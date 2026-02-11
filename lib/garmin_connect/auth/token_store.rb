# frozen_string_literal: true

require "json"
require "base64"
require "fileutils"

module GarminConnect
  module Auth
    # Handles token persistence to disk or serialization to strings.
    # Compatible with garth's token storage format for interoperability.
    module TokenStore
      OAUTH1_FILENAME = "oauth1_token.json"
      OAUTH2_FILENAME = "oauth2_token.json"

      module_function

      # Save tokens to a directory as JSON files.
      def save(directory, oauth1_token:, oauth2_token:)
        FileUtils.mkdir_p(directory)

        File.write(
          File.join(directory, OAUTH1_FILENAME),
          JSON.pretty_generate(oauth1_token.to_h)
        )
        File.write(
          File.join(directory, OAUTH2_FILENAME),
          JSON.pretty_generate(oauth2_token.to_h)
        )

        directory
      end

      # Save only the OAuth2 token (used after refresh).
      def save_oauth2(directory, oauth2_token:)
        FileUtils.mkdir_p(directory)

        File.write(
          File.join(directory, OAUTH2_FILENAME),
          JSON.pretty_generate(oauth2_token.to_h)
        )

        directory
      end

      # Load tokens from a directory.
      # Returns [OAuth1Token, OAuth2Token] or raises if files are missing.
      def load(directory)
        oauth1_path = File.join(directory, OAUTH1_FILENAME)
        oauth2_path = File.join(directory, OAUTH2_FILENAME)

        raise Error, "Token directory not found: #{directory}" unless Dir.exist?(directory)
        raise Error, "OAuth1 token file not found: #{oauth1_path}" unless File.exist?(oauth1_path)
        raise Error, "OAuth2 token file not found: #{oauth2_path}" unless File.exist?(oauth2_path)

        oauth1 = OAuth1Token.from_hash(JSON.parse(File.read(oauth1_path)))
        oauth2 = OAuth2Token.from_hash(JSON.parse(File.read(oauth2_path)))

        [oauth1, oauth2]
      end

      # Serialize both tokens to a single base64-encoded string.
      # Compatible with garth's dumps/loads format.
      def dumps(oauth1_token:, oauth2_token:)
        payload = [oauth1_token.to_h, oauth2_token.to_h]
        Base64.strict_encode64(JSON.generate(payload))
      end

      # Deserialize tokens from a base64-encoded string.
      # Returns [OAuth1Token, OAuth2Token].
      def loads(encoded_string)
        decoded = JSON.parse(Base64.strict_decode64(encoded_string))
        oauth1 = OAuth1Token.from_hash(decoded[0])
        oauth2 = OAuth2Token.from_hash(decoded[1])

        [oauth1, oauth2]
      end
    end
  end
end
