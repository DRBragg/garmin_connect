# frozen_string_literal: true

require "faraday"
require "faraday/retry"
require "json"

module GarminConnect
  # Handles authenticated HTTP requests to the Garmin Connect API.
  # Automatically refreshes expired OAuth2 tokens using the OAuth1 token.
  class Connection
    API_BASE = "https://connectapi.garmin.com"
    USER_AGENT = "GCM-iOS-5.19.1.2"

    RETRY_OPTIONS = {
      max: 3,
      interval: 0.5,
      backoff_factor: 2,
      retry_statuses: [408, 500, 502, 503, 504]
    }.freeze

    attr_reader :domain

    def initialize(oauth1_token:, oauth2_token:, domain: "garmin.com", token_dir: nil)
      @oauth1_token = oauth1_token
      @oauth2_token = oauth2_token
      @domain = domain || "garmin.com"
      @token_dir = token_dir
    end

    # Make an authenticated GET request.
    def get(path, params: {})
      request(:get, path, params: params)
    end

    # Make an authenticated POST request with a JSON body.
    def post(path, body: nil, params: {})
      request(:post, path, body: body, params: params)
    end

    # Make an authenticated PUT request with a JSON body.
    def put(path, body: nil, params: {})
      request(:put, path, body: body, params: params)
    end

    # Make an authenticated DELETE request.
    def delete(path, params: {})
      request(:delete, path, params: params)
    end

    # Download raw bytes (for FIT/GPX/TCX file downloads).
    def download(path, params: {})
      ensure_valid_token!
      resp = connection.get(path) do |req|
        req.headers["Authorization"] = @oauth2_token.authorization_header
        req.params = params unless params.empty?
      end
      handle_errors!(resp)
      resp.body
    end

    # Upload a file (multipart form).
    def upload(path, file_path:, file_name: nil)
      ensure_valid_token!
      name = file_name || File.basename(file_path)
      payload = { file: Faraday::Multipart::FilePart.new(file_path, nil, name) }

      resp = upload_connection.post(path) do |req|
        req.headers["Authorization"] = @oauth2_token.authorization_header
        req.body = payload
      end
      handle_errors!(resp)
      parse_response(resp)
    end

    private

    def request(method, path, body: nil, params: {})
      ensure_valid_token!

      resp = connection.public_send(method, path) do |req|
        req.headers["Authorization"] = @oauth2_token.authorization_header
        req.params = params unless params.empty?

        if body && %i[post put].include?(method)
          req.headers["Content-Type"] = "application/json"
          req.body = body.is_a?(String) ? body : JSON.generate(body)
        end
      end

      handle_errors!(resp)
      parse_response(resp)
    end

    def ensure_valid_token!
      return unless @oauth2_token.expired?

      @oauth2_token = Auth::SSO.refresh(@oauth1_token, domain: @domain)
      Auth::TokenStore.save_oauth2(@token_dir, oauth2_token: @oauth2_token) if @token_dir
    end

    def connection
      @connection ||= Faraday.new(url: api_base) do |f|
        f.request :retry, **RETRY_OPTIONS
        f.adapter Faraday.default_adapter
      end.tap do |conn|
        conn.headers["User-Agent"] = USER_AGENT
        conn.headers["Accept"] = "application/json"
      end
    end

    def upload_connection
      @upload_connection ||= Faraday.new(url: api_base) do |f|
        f.request :multipart
        f.request :retry, **RETRY_OPTIONS
        f.adapter Faraday.default_adapter
      end.tap do |conn|
        conn.headers["User-Agent"] = USER_AGENT
      end
    end

    def api_base
      "https://connectapi.#{@domain}"
    end

    def parse_response(resp)
      return nil if resp.status == 204

      body = resp.body
      return body if body.nil? || body.empty?

      # Strip UTF-8 BOM if present (some Garmin endpoints include it)
      body = body.b.sub(/\A\xEF\xBB\xBF/n, "").force_encoding("UTF-8")

      JSON.parse(body)
    rescue JSON::ParserError
      content_type = resp.headers["content-type"].to_s
      # If the server said it was JSON but we can't parse it, raise rather than
      # returning a raw string that callers will misuse.
      if content_type.include?("application/json")
        raise ParseError, "Failed to parse JSON response: #{body[0..200]}"
      end

      body
    end

    def handle_errors!(resp)
      return if resp.success?

      error_class = HTTP_ERRORS.fetch(resp.status) do
        resp.status >= 500 ? ServerError : HTTPError
      end

      raise error_class.new(
        "Garmin API error: HTTP #{resp.status}",
        status: resp.status,
        body: resp.body
      )
    end
  end
end
