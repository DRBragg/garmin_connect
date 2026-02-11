# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe GarminConnect::Auth::TokenStore do
  let(:oauth1) { build_oauth1_token }
  let(:oauth2) { build_oauth2_token }

  describe ".save and .load" do
    it "round-trips tokens through the filesystem" do
      Dir.mktmpdir do |dir|
        described_class.save(dir, oauth1_token: oauth1, oauth2_token: oauth2)

        loaded_oauth1, loaded_oauth2 = described_class.load(dir)

        expect(loaded_oauth1.token).to eq(oauth1.token)
        expect(loaded_oauth1.secret).to eq(oauth1.secret)
        expect(loaded_oauth1.domain).to eq(oauth1.domain)
        expect(loaded_oauth2.access_token).to eq(oauth2.access_token)
        expect(loaded_oauth2.refresh_token).to eq(oauth2.refresh_token)
      end
    end

    it "creates the directory if it doesn't exist" do
      Dir.mktmpdir do |parent|
        dir = File.join(parent, "nested", "tokens")
        described_class.save(dir, oauth1_token: oauth1, oauth2_token: oauth2)

        expect(Dir.exist?(dir)).to be true
        expect(File.exist?(File.join(dir, "oauth1_token.json"))).to be true
        expect(File.exist?(File.join(dir, "oauth2_token.json"))).to be true
      end
    end

    it "writes pretty-printed JSON" do
      Dir.mktmpdir do |dir|
        described_class.save(dir, oauth1_token: oauth1, oauth2_token: oauth2)
        content = File.read(File.join(dir, "oauth1_token.json"))

        expect(content).to include("\n")
        expect(JSON.parse(content)["oauth_token"]).to eq(oauth1.token)
      end
    end
  end

  describe ".save_oauth2" do
    it "only writes the OAuth2 token file" do
      Dir.mktmpdir do |dir|
        described_class.save_oauth2(dir, oauth2_token: oauth2)

        expect(File.exist?(File.join(dir, "oauth2_token.json"))).to be true
        expect(File.exist?(File.join(dir, "oauth1_token.json"))).to be false
      end
    end
  end

  describe ".load" do
    it "raises when directory does not exist" do
      expect { described_class.load("/nonexistent/path") }
        .to raise_error(GarminConnect::Error, /not found/)
    end

    it "raises when token files are missing" do
      Dir.mktmpdir do |dir|
        expect { described_class.load(dir) }
          .to raise_error(GarminConnect::Error, /OAuth1 token file not found/)
      end
    end
  end

  describe ".dumps and .loads" do
    it "round-trips tokens through a base64 string" do
      encoded = described_class.dumps(oauth1_token: oauth1, oauth2_token: oauth2)

      expect(encoded).to be_a(String)
      expect(encoded.length).to be > 50

      loaded_oauth1, loaded_oauth2 = described_class.loads(encoded)

      expect(loaded_oauth1.token).to eq(oauth1.token)
      expect(loaded_oauth2.access_token).to eq(oauth2.access_token)
    end

    it "produces a base64-decodable string" do
      encoded = described_class.dumps(oauth1_token: oauth1, oauth2_token: oauth2)
      decoded = Base64.strict_decode64(encoded)
      parsed = JSON.parse(decoded)

      expect(parsed).to be_an(Array)
      expect(parsed.length).to eq(2)
      expect(parsed[0]["oauth_token"]).to eq(oauth1.token)
    end
  end
end
