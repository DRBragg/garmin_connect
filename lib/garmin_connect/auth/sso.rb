# frozen_string_literal: true

require "uri"
require "cgi"
require "json"
require "net/http"
require "faraday"
require "faraday/cookie_jar"
require "faraday/follow_redirects"
require "oauth"

module GarminConnect
  module Auth
    # Handles the Garmin SSO login flow and OAuth token exchanges.
    #
    # The flow mirrors the mobile app authentication:
    #   1. Load SSO embed page (establish cookies)
    #   2. Load signin page (extract CSRF token)
    #   3. POST credentials (email + password)
    #   4. Handle MFA if required
    #   5. Extract SSO ticket from success page
    #   6. Exchange ticket for OAuth1 token (via consumer key/secret)
    #   7. Exchange OAuth1 for OAuth2 Bearer token
    module SSO
      CONSUMER_URL = "https://thegarth.s3.amazonaws.com/oauth_consumer.json"

      SSO_USER_AGENT = "GCM-iOS-5.19.1.2"
      OAUTH_USER_AGENT = "com.garmin.android.apps.connectmobile"

      CSRF_RE = /name="_csrf"\s+value="(.+?)"/
      TITLE_RE = /<title>(.+?)<\/title>/m
      TICKET_RE = /embed\?ticket=([^"]+)"/

      module_function

      # Perform a full login and return [OAuth1Token, OAuth2Token].
      #
      # @param email [String] Garmin account email
      # @param password [String] Garmin account password
      # @param domain [String] Garmin domain ("garmin.com" or "garmin.cn")
      # @param mfa_handler [Proc, nil] Called with no args when MFA is needed; must return the code.
      #   Defaults to reading from $stdin.
      # @return [Array(OAuth1Token, OAuth2Token)]
      def login(email:, password:, domain: "garmin.com", mfa_handler: nil)
        sso_base = "https://sso.#{domain}/sso"
        conn = build_sso_connection

        # Step 1: Establish SSO cookies
        conn.get(embed_url(sso_base))

        # Step 2: Load signin page and extract CSRF
        signin_get_url = signin_url(sso_base)
        resp = conn.get(signin_get_url) do |req|
          req.headers["Referer"] = "#{sso_base}/embed"
        end
        csrf = extract_csrf(resp.body)

        # Step 3: Submit credentials
        resp = conn.post(signin_get_url) do |req|
          req.headers["Referer"] = signin_get_url
          req.headers["Content-Type"] = "application/x-www-form-urlencoded"
          req.body = URI.encode_www_form(
            "username" => email,
            "password" => password,
            "embed" => "true",
            "_csrf" => csrf
          )
        end

        title = extract_title(resp.body)

        # Step 4: Handle MFA
        if title.downcase.include?("mfa")
          resp = handle_mfa(conn, resp.body, sso_base, mfa_handler)
          title = extract_title(resp.body)
        end

        raise LoginError, "Login failed. Response title: '#{title}'" unless title == "Success"

        # Step 5: Extract SSO ticket
        ticket = extract_ticket(resp.body)

        # Steps 6-7: Exchange ticket -> OAuth1 -> OAuth2
        consumer_key, consumer_secret = fetch_consumer_credentials
        oauth1 = exchange_ticket(ticket, consumer_key, consumer_secret, domain)
        oauth2 = exchange_oauth1(oauth1, consumer_key, consumer_secret, domain)

        [oauth1, oauth2]
      end

      # Exchange an existing OAuth1 token for a fresh OAuth2 token.
      # Used for token refresh without re-logging in.
      #
      # @param oauth1_token [OAuth1Token]
      # @param domain [String]
      # @return [OAuth2Token]
      def refresh(oauth1_token, domain: nil)
        domain ||= oauth1_token.domain || "garmin.com"
        consumer_key, consumer_secret = fetch_consumer_credentials
        exchange_oauth1(oauth1_token, consumer_key, consumer_secret, domain)
      end

      # --- Private helpers ---

      def build_sso_connection
        Faraday.new do |f|
          f.use :cookie_jar
          f.response :follow_redirects
          f.adapter Faraday.default_adapter
        end.tap do |conn|
          conn.headers["User-Agent"] = SSO_USER_AGENT
        end
      end

      def embed_url(sso_base)
        params = {
          "id" => "gauth-widget",
          "embedWidget" => "true",
          "gauthHost" => sso_base
        }
        "#{sso_base}/embed?#{URI.encode_www_form(params)}"
      end

      def signin_url(sso_base)
        embed = "#{sso_base}/embed"
        params = {
          "id" => "gauth-widget",
          "embedWidget" => "true",
          "gauthHost" => embed,
          "service" => embed,
          "source" => embed,
          "redirectAfterAccountLoginUrl" => embed,
          "redirectAfterAccountCreationUrl" => embed
        }
        "#{sso_base}/signin?#{URI.encode_www_form(params)}"
      end

      def handle_mfa(conn, html, sso_base, mfa_handler)
        csrf = extract_csrf(html)

        code = if mfa_handler
                 mfa_handler.call
               else
                 $stderr.print "Enter Garmin MFA code: "
                 $stderr.flush
                 $stdin.gets&.chomp
               end

        raise AuthenticationError, "No MFA code provided" if code.nil? || code.empty?

        mfa_url = "#{sso_base}/verifyMFA/loginEnterMfaCode?#{URI.encode_www_form(signin_params(sso_base))}"
        conn.post(mfa_url) do |req|
          req.headers["Referer"] = "#{sso_base}/verifyMFA/loginEnterMfaCode"
          req.headers["Content-Type"] = "application/x-www-form-urlencoded"
          req.body = URI.encode_www_form(
            "mfa-code" => code,
            "embed" => "true",
            "_csrf" => csrf,
            "fromPage" => "setupEnterMfaCode"
          )
        end
      end

      def signin_params(sso_base)
        embed = "#{sso_base}/embed"
        {
          "id" => "gauth-widget",
          "embedWidget" => "true",
          "gauthHost" => embed,
          "service" => embed,
          "source" => embed,
          "redirectAfterAccountLoginUrl" => embed,
          "redirectAfterAccountCreationUrl" => embed
        }
      end

      def fetch_consumer_credentials
        resp = Faraday.get(CONSUMER_URL)
        raise AuthenticationError, "Failed to fetch OAuth consumer credentials" unless resp.success?

        data = JSON.parse(resp.body)
        [data["consumer_key"], data["consumer_secret"]]
      end

      def exchange_ticket(ticket, consumer_key, consumer_secret, domain)
        sso_base = "https://sso.#{domain}/sso"
        api_base = "https://connectapi.#{domain}"

        uri = URI.parse(
          "#{api_base}/oauth-service/oauth/preauthorized?" \
          "#{URI.encode_www_form("ticket" => ticket, "login-url" => "#{sso_base}/embed", "accepts-mfa-tokens" => "true")}"
        )

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.open_timeout = 10
        http.read_timeout = 10

        request = Net::HTTP::Get.new(uri.request_uri)
        request["User-Agent"] = OAUTH_USER_AGENT

        consumer = OAuth::Consumer.new(consumer_key, consumer_secret, site: api_base, scheme: :header)
        helper = OAuth::Client::Helper.new(
          request,
          { consumer: consumer, request_uri: uri.to_s, signature_method: "HMAC-SHA1" }
        )
        request["Authorization"] = helper.header

        response = http.request(request)
        raise AuthenticationError, "OAuth1 exchange failed: HTTP #{response.code}" unless response.code == "200"

        data = CGI.parse(response.body).transform_values(&:first)

        OAuth1Token.new(
          token: data["oauth_token"],
          secret: data["oauth_token_secret"],
          mfa_token: data["mfa_token"],
          mfa_expiration: data["mfa_expiration_timestamp"],
          domain: domain
        )
      end

      def exchange_oauth1(oauth1_token, consumer_key, consumer_secret, domain)
        api_base = "https://connectapi.#{domain}"
        url = "#{api_base}/oauth-service/oauth/exchange/user/2.0"
        uri = URI.parse(url)

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.open_timeout = 10
        http.read_timeout = 10

        request = Net::HTTP::Post.new(uri.request_uri)
        request["User-Agent"] = OAUTH_USER_AGENT
        request["Content-Type"] = "application/x-www-form-urlencoded"

        request.body = if oauth1_token.mfa_token && !oauth1_token.mfa_token.empty?
                         URI.encode_www_form("mfa_token" => oauth1_token.mfa_token)
                       else
                         ""
                       end

        consumer = OAuth::Consumer.new(consumer_key, consumer_secret, site: api_base, scheme: :header)
        access_token = OAuth::AccessToken.new(consumer, oauth1_token.token, oauth1_token.secret)

        helper = OAuth::Client::Helper.new(
          request,
          {
            consumer: consumer,
            token: access_token,
            request_uri: url,
            signature_method: "HMAC-SHA1"
          }
        )
        request["Authorization"] = helper.header

        response = http.request(request)
        raise AuthenticationError, "OAuth2 exchange failed: HTTP #{response.code}" unless response.code == "200"

        data = JSON.parse(response.body)

        OAuth2Token.new(
          access_token: data["access_token"],
          refresh_token: data["refresh_token"],
          token_type: data["token_type"] || "Bearer",
          scope: data["scope"],
          jti: data["jti"],
          expires_in: data["expires_in"],
          expires_at: (Time.now.to_i + data["expires_in"]),
          refresh_token_expires_in: data["refresh_token_expires_in"],
          refresh_token_expires_at: data["refresh_token_expires_in"] ? (Time.now.to_i + data["refresh_token_expires_in"]) : nil
        )
      end

      private_class_method :build_sso_connection, :embed_url, :signin_url,
                           :handle_mfa, :signin_params, :fetch_consumer_credentials,
                           :exchange_ticket, :exchange_oauth1

      # --- Regex extraction ---

      def extract_csrf(html)
        match = html.match(CSRF_RE)
        raise LoginError, "Could not extract CSRF token from SSO page" unless match

        match[1]
      end

      def extract_title(html)
        match = html.match(TITLE_RE)
        match ? match[1].strip : ""
      end

      def extract_ticket(html)
        match = html.match(TICKET_RE)
        raise LoginError, "Could not extract SSO ticket from success page" unless match

        match[1]
      end

      private_class_method :extract_csrf, :extract_title, :extract_ticket
    end
  end
end
