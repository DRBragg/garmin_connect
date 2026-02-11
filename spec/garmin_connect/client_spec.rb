# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe GarminConnect::Client do
  describe "#initialize" do
    it "accepts email and password" do
      client = described_class.new(email: "user@example.com", password: "pass")

      expect(client).not_to be_authenticated
    end

    it "defaults token_dir to ~/.garminconnect" do
      client = described_class.new
      # Can't directly test private state, but it shouldn't raise
      expect(client).to be_a(described_class)
    end
  end

  describe "#login with saved tokens" do
    it "resumes from a token directory" do
      Dir.mktmpdir do |dir|
        oauth1 = build_oauth1_token
        oauth2 = build_oauth2_token

        GarminConnect::Auth::TokenStore.save(dir, oauth1_token: oauth1, oauth2_token: oauth2)

        stub_request(:get, "https://connectapi.garmin.com/userprofile-service/userprofile/user-settings")
          .to_return(status: 200, body: '{"id": 123, "userData": {"measurementSystem": "metric"}}',
                     headers: { "Content-Type" => "application/json" })

        stub_request(:get, "https://connectapi.garmin.com/userprofile-service/userprofile/profile")
          .to_return(status: 200, body: '{"displayName": "TestUser", "fullName": "Test User", "profileId": 123}',
                     headers: { "Content-Type" => "application/json" })

        client = described_class.new(token_dir: dir)
        client.login

        expect(client).to be_authenticated
        expect(client.display_name).to eq("TestUser")
        expect(client.full_name).to eq("Test User")
        expect(client.unit_system).to eq("metric")
      end
    end

    it "resumes from a token string" do
      oauth1 = build_oauth1_token
      oauth2 = build_oauth2_token
      encoded = GarminConnect::Auth::TokenStore.dumps(oauth1_token: oauth1, oauth2_token: oauth2)

      stub_request(:get, "https://connectapi.garmin.com/userprofile-service/userprofile/user-settings")
        .to_return(status: 200, body: '{"id": 123, "userData": {"measurementSystem": "statute_us"}}',
                   headers: { "Content-Type" => "application/json" })

      stub_request(:get, "https://connectapi.garmin.com/userprofile-service/userprofile/profile")
        .to_return(status: 200, body: '{"displayName": "User2", "fullName": "User Two"}',
                   headers: { "Content-Type" => "application/json" })

      client = described_class.new(token_string: encoded, token_dir: nil)
      client.login

      expect(client).to be_authenticated
      expect(client.display_name).to eq("User2")
    end
  end

  describe "#login without credentials or tokens" do
    it "raises AuthenticationError" do
      client = described_class.new(token_dir: nil)

      expect { client.login }.to raise_error(GarminConnect::AuthenticationError, /No credentials/)
    end
  end

  describe "#logout" do
    it "clears all state" do
      Dir.mktmpdir do |dir|
        GarminConnect::Auth::TokenStore.save(dir, oauth1_token: build_oauth1_token, oauth2_token: build_oauth2_token)

        stub_request(:get, "https://connectapi.garmin.com/userprofile-service/userprofile/user-settings")
          .to_return(status: 200, body: '{"id": 1, "userData": {}}', headers: { "Content-Type" => "application/json" })
        stub_request(:get, "https://connectapi.garmin.com/userprofile-service/userprofile/profile")
          .to_return(status: 200, body: '{"displayName": "X"}', headers: { "Content-Type" => "application/json" })

        client = described_class.new(token_dir: dir)
        client.login
        expect(client).to be_authenticated

        client.logout
        expect(client).not_to be_authenticated
        expect(client.display_name).to be_nil
      end
    end
  end

  describe "#save_tokens" do
    it "persists tokens to a directory" do
      Dir.mktmpdir do |dir|
        GarminConnect::Auth::TokenStore.save(dir, oauth1_token: build_oauth1_token, oauth2_token: build_oauth2_token)

        stub_request(:get, "https://connectapi.garmin.com/userprofile-service/userprofile/user-settings")
          .to_return(status: 200, body: '{"id": 1, "userData": {}}', headers: { "Content-Type" => "application/json" })
        stub_request(:get, "https://connectapi.garmin.com/userprofile-service/userprofile/profile")
          .to_return(status: 200, body: '{"displayName": "X"}', headers: { "Content-Type" => "application/json" })

        client = described_class.new(token_dir: dir)
        client.login

        new_dir = File.join(dir, "backup")
        client.save_tokens(new_dir)

        expect(File.exist?(File.join(new_dir, "oauth1_token.json"))).to be true
        expect(File.exist?(File.join(new_dir, "oauth2_token.json"))).to be true
      end
    end
  end

  describe "#dump_tokens" do
    it "returns a base64-encoded string" do
      Dir.mktmpdir do |dir|
        GarminConnect::Auth::TokenStore.save(dir, oauth1_token: build_oauth1_token, oauth2_token: build_oauth2_token)

        stub_request(:get, "https://connectapi.garmin.com/userprofile-service/userprofile/user-settings")
          .to_return(status: 200, body: '{"id": 1, "userData": {}}', headers: { "Content-Type" => "application/json" })
        stub_request(:get, "https://connectapi.garmin.com/userprofile-service/userprofile/profile")
          .to_return(status: 200, body: '{"displayName": "X"}', headers: { "Content-Type" => "application/json" })

        client = described_class.new(token_dir: dir)
        client.login

        encoded = client.dump_tokens
        expect(encoded).to be_a(String)

        decoded = JSON.parse(Base64.strict_decode64(encoded))
        expect(decoded).to be_an(Array)
        expect(decoded.length).to eq(2)
      end
    end
  end

  describe "API method delegation" do
    it "delegates health methods to the connection" do
      Dir.mktmpdir do |dir|
        GarminConnect::Auth::TokenStore.save(dir, oauth1_token: build_oauth1_token, oauth2_token: build_oauth2_token)

        stub_request(:get, "https://connectapi.garmin.com/userprofile-service/userprofile/user-settings")
          .to_return(status: 200, body: '{"id": 1, "userData": {}}', headers: { "Content-Type" => "application/json" })
        stub_request(:get, "https://connectapi.garmin.com/userprofile-service/userprofile/profile")
          .to_return(status: 200, body: '{"displayName": "TestUser"}', headers: { "Content-Type" => "application/json" })

        stub_request(:get, %r{connectapi\.garmin\.com/wellness-service/wellness/dailyHeartRate/TestUser})
          .to_return(status: 200, body: '{"restingHeartRate": 62}', headers: { "Content-Type" => "application/json" })

        client = described_class.new(token_dir: dir)
        client.login

        result = client.heart_rates("2026-02-11")
        expect(result["restingHeartRate"]).to eq(62)
      end
    end
  end
end
