# frozen_string_literal: true

module GarminConnect
  module Auth
    # Represents an OAuth1 token pair obtained from the SSO ticket exchange.
    # These tokens are long-lived (~1 year) and used to mint OAuth2 tokens.
    class OAuth1Token
      attr_reader :token, :secret, :mfa_token, :mfa_expiration, :domain

      def initialize(token:, secret:, mfa_token: nil, mfa_expiration: nil, domain: "garmin.com")
        @token = token
        @secret = secret
        @mfa_token = mfa_token
        @mfa_expiration = mfa_expiration
        @domain = domain
      end

      def to_h
        {
          "oauth_token" => token,
          "oauth_token_secret" => secret,
          "mfa_token" => mfa_token,
          "mfa_expiration_timestamp" => mfa_expiration,
          "domain" => domain
        }
      end

      def to_json(...)
        to_h.to_json(...)
      end

      def self.from_hash(data)
        new(
          token: data["oauth_token"],
          secret: data["oauth_token_secret"],
          mfa_token: data["mfa_token"],
          mfa_expiration: data["mfa_expiration_timestamp"],
          domain: data["domain"] || "garmin.com"
        )
      end
    end
  end
end
