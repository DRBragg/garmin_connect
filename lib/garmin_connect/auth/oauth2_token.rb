# frozen_string_literal: true

module GarminConnect
  module Auth
    # Represents an OAuth2 Bearer token used for API requests.
    # Short-lived, but can be refreshed by re-exchanging the OAuth1 token.
    class OAuth2Token
      attr_reader :access_token, :refresh_token, :token_type, :scope,
                  :jti, :expires_in, :expires_at,
                  :refresh_token_expires_in, :refresh_token_expires_at

      def initialize(access_token:, refresh_token: nil, token_type: "Bearer",
                     scope: nil, jti: nil, expires_in: 3600, expires_at: nil,
                     refresh_token_expires_in: nil, refresh_token_expires_at: nil)
        @access_token = access_token
        @refresh_token = refresh_token
        @token_type = token_type
        @scope = scope
        @jti = jti
        @expires_in = expires_in
        @expires_at = expires_at || (Time.now.to_i + expires_in)
        @refresh_token_expires_in = refresh_token_expires_in
        @refresh_token_expires_at = refresh_token_expires_at ||
          (refresh_token_expires_in ? Time.now.to_i + refresh_token_expires_in : nil)
      end

      def expired?
        Time.now.to_i >= expires_at
      end

      def authorization_header
        "#{token_type.capitalize} #{access_token}"
      end

      alias_method :to_s, :authorization_header

      def to_h
        {
          "access_token" => access_token,
          "refresh_token" => refresh_token,
          "token_type" => token_type,
          "scope" => scope,
          "jti" => jti,
          "expires_in" => expires_in,
          "expires_at" => expires_at,
          "refresh_token_expires_in" => refresh_token_expires_in,
          "refresh_token_expires_at" => refresh_token_expires_at
        }
      end

      def to_json(...)
        to_h.to_json(...)
      end

      def self.from_hash(data)
        new(
          access_token: data["access_token"],
          refresh_token: data["refresh_token"],
          token_type: data["token_type"] || "Bearer",
          scope: data["scope"],
          jti: data["jti"],
          expires_in: data["expires_in"],
          expires_at: data["expires_at"],
          refresh_token_expires_in: data["refresh_token_expires_in"],
          refresh_token_expires_at: data["refresh_token_expires_at"]
        )
      end
    end
  end
end
