# frozen_string_literal: true

require "date"

module GarminConnect
  # The main entry point for interacting with the Garmin Connect API.
  #
  # @example Basic usage
  #   client = GarminConnect::Client.new(email: "user@example.com", password: "secret")
  #   client.login
  #   puts client.daily_summary
  #
  # @example Resume from saved tokens
  #   client = GarminConnect::Client.new(token_dir: "~/.garminconnect")
  #   client.login
  #   puts client.heart_rates
  #
  # @example With MFA handler
  #   client = GarminConnect::Client.new(
  #     email: "user@example.com",
  #     password: "secret",
  #     mfa_handler: -> { print "MFA code: "; gets.chomp }
  #   )
  #   client.login
  class Client
    include API::User
    include API::Health
    include API::Activities
    include API::BodyComposition
    include API::Metrics
    include API::Devices
    include API::Badges
    include API::Workouts
    include API::Wellness

    DEFAULT_TOKEN_DIR = File.expand_path("~/.garminconnect")

    attr_reader :connection

    # @param email [String, nil] Garmin account email
    # @param password [String, nil] Garmin account password
    # @param domain [String] "garmin.com" or "garmin.cn"
    # @param token_dir [String, nil] directory for token persistence (default: ~/.garminconnect)
    # @param token_string [String, nil] base64-encoded token string (alternative to token_dir)
    # @param mfa_handler [Proc, nil] called when MFA is needed; must return the code
    def initialize(email: nil, password: nil, domain: "garmin.com",
                   token_dir: DEFAULT_TOKEN_DIR, token_string: nil,
                   mfa_handler: nil)
      @email = email
      @password = password
      @domain = domain
      @token_dir = token_dir ? File.expand_path(token_dir) : nil
      @token_string = token_string
      @mfa_handler = mfa_handler

      @display_name = nil
      @full_name = nil
      @unit_system = nil
      @user_profile_pk = nil
    end

    # Authenticate with Garmin Connect.
    # Attempts to resume from saved tokens first, falling back to a fresh login.
    #
    # @return [self]
    def login
      if resume_from_tokens
        setup_user_info
      elsif @email && @password
        fresh_login
      else
        raise AuthenticationError, "No credentials or saved tokens available"
      end

      self
    end

    # Check if the client is authenticated with valid tokens.
    def authenticated?
      @connection && !@oauth2_token.nil?
    end

    # Save the current tokens to the configured token directory.
    # @param directory [String, nil] override the default token directory
    def save_tokens(directory = @token_dir)
      raise Error, "No tokens to save" unless @oauth1_token && @oauth2_token

      Auth::TokenStore.save(
        directory || DEFAULT_TOKEN_DIR,
        oauth1_token: @oauth1_token,
        oauth2_token: @oauth2_token
      )
    end

    # Serialize tokens to a base64-encoded string.
    # @return [String]
    def dump_tokens
      raise Error, "No tokens to dump" unless @oauth1_token && @oauth2_token

      Auth::TokenStore.dumps(oauth1_token: @oauth1_token, oauth2_token: @oauth2_token)
    end

    # Log out (clears in-memory tokens).
    def logout
      @oauth1_token = nil
      @oauth2_token = nil
      @connection = nil
      @display_name = nil
      @full_name = nil
      @unit_system = nil
      @user_profile_pk = nil
    end

    private

    def resume_from_tokens
      oauth1, oauth2 = load_tokens
      return false unless oauth1 && oauth2

      @oauth1_token = oauth1
      @oauth2_token = oauth2
      @domain = oauth1.domain || @domain
      build_connection

      true
    rescue GarminConnect::Error
      false
    end

    def load_tokens
      if @token_string
        Auth::TokenStore.loads(@token_string)
      elsif @token_dir && Dir.exist?(@token_dir)
        Auth::TokenStore.load(@token_dir)
      end
    end

    def fresh_login
      @oauth1_token, @oauth2_token = Auth::SSO.login(
        email: @email,
        password: @password,
        domain: @domain,
        mfa_handler: @mfa_handler
      )

      build_connection
      save_tokens if @token_dir
      setup_user_info
    end

    def build_connection
      @connection = Connection.new(
        oauth1_token: @oauth1_token,
        oauth2_token: @oauth2_token,
        domain: @domain,
        token_dir: @token_dir
      )
    end

    def setup_user_info
      settings = user_settings
      @unit_system = settings&.dig("userData", "measurementSystem")

      profile = connection.get("/userprofile-service/userprofile/profile")
      @display_name = profile&.dig("displayName")
      @full_name = profile&.dig("fullName")
      @user_profile_pk = profile&.dig("profileId") || settings&.dig("id")
    rescue HTTPError
      # Non-fatal: display_name may not be available
    end

    # Exposed for API modules that need it.
    def user_profile_pk
      @user_profile_pk
    end

    # --- Date helpers ---

    def today
      Date.today.strftime("%Y-%m-%d")
    end

    def format_date(date)
      case date
      when Date, Time, DateTime
        date.strftime("%Y-%m-%d")
      when String
        date
      else
        date.to_s
      end
    end

    # Auto-chunk large date ranges into smaller windows.
    # @param start_date [Date, String]
    # @param end_date [Date, String]
    # @param max_days [Integer] maximum days per chunk
    def chunked_request(start_date, end_date, max_days)
      start_d = start_date.is_a?(Date) ? start_date : Date.parse(start_date.to_s)
      end_d = end_date.is_a?(Date) ? end_date : Date.parse(end_date.to_s)
      results = []

      while start_d <= end_d
        chunk_end = [start_d + max_days - 1, end_d].min
        chunk = yield(start_d, chunk_end)
        results.concat(Array(chunk))
        start_d = chunk_end + 1
      end

      results
    end
  end
end
