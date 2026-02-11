# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe GarminConnect::API::User do
  describe "#user_settings" do
    it "returns the user settings hash" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/userprofile-service/userprofile/user-settings",
        response_body: {"id" => 456, "userData" => {"measurementSystem" => "statute_us", "weight" => 75.0}})

      result = client.user_settings

      expect(result).to eq("id" => 456, "userData" => {"measurementSystem" => "statute_us", "weight" => 75.0})
    end

    it "returns the response as parsed JSON" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/userprofile-service/userprofile/user-settings",
        response_body: {"id" => 789, "userData" => {}})

      result = client.user_settings

      expect(result).to be_a(Hash)
      expect(result["id"]).to eq(789)
    end
  end

  describe "#user_profile" do
    it "returns the user profile settings hash" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/userprofile-service/userprofile/settings",
        response_body: {"userName" => "TestUser", "locale" => "en_US", "timeFormat" => "24hour"})

      result = client.user_profile

      expect(result).to eq("userName" => "TestUser", "locale" => "en_US", "timeFormat" => "24hour")
    end

    it "returns the response as parsed JSON" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/userprofile-service/userprofile/settings",
        response_body: {"userName" => "AnotherUser"})

      result = client.user_profile

      expect(result).to be_a(Hash)
      expect(result["userName"]).to eq("AnotherUser")
    end
  end

  describe "#personal_information" do
    it "uses the logged-in display_name by default" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/userprofile-service/userprofile/personal-information/TestUser",
        response_body: {"displayName" => "TestUser", "age" => 30, "gender" => "MALE"})

      result = client.personal_information

      expect(result).to eq("displayName" => "TestUser", "age" => 30, "gender" => "MALE")
    end

    it "accepts an explicit display_name override" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/userprofile-service/userprofile/personal-information/OtherUser",
        response_body: {"displayName" => "OtherUser", "age" => 25})

      result = client.personal_information("OtherUser")

      expect(result).to eq("displayName" => "OtherUser", "age" => 25)
    end
  end

  describe "#display_name" do
    it "returns the display name set during login" do
      client = build_logged_in_client

      expect(client.display_name).to eq("TestUser")
    end

    it "extracts display_name from nested socialProfile" do
      client = build_logged_in_client(
        profile_body: { "socialProfile" => { "displayName" => "NestedUser", "fullName" => "Nested Name" } })

      expect(client.display_name).to eq("NestedUser")
    end

    it "falls back to userName when displayName is missing" do
      client = build_logged_in_client(
        profile_body: { "userName" => "FallbackUser", "profileId" => 123 })

      expect(client.display_name).to eq("FallbackUser")
    end
  end

  describe "#full_name" do
    it "returns the full name set during login" do
      client = build_logged_in_client

      expect(client.full_name).to eq("Test User")
    end

    it "extracts full_name from nested socialProfile" do
      client = build_logged_in_client(
        profile_body: { "socialProfile" => { "displayName" => "X", "fullName" => "Nested Full Name" } })

      expect(client.full_name).to eq("Nested Full Name")
    end
  end

  describe "#unit_system" do
    it "returns the unit system set during login" do
      client = build_logged_in_client

      expect(client.unit_system).to eq("metric")
    end

    it "reflects the measurement system from user settings" do
      client = build_logged_in_client(
        settings_body: {"id" => 123, "userData" => {"measurementSystem" => "statute_us"}})

      expect(client.unit_system).to eq("statute_us")
    end
  end

  private

  def build_logged_in_client(settings_body: nil, profile_body: nil)
    dir = Dir.mktmpdir

    GarminConnect::Auth::TokenStore.save(dir,
      oauth1_token: build_oauth1_token,
      oauth2_token: build_oauth2_token)

    settings = settings_body || {"id" => 123, "userData" => {"measurementSystem" => "metric"}}
    profile = profile_body || {"displayName" => "TestUser", "fullName" => "Test User", "profileId" => 123}

    stub_request(:get, "https://connectapi.garmin.com/userprofile-service/userprofile/user-settings")
      .to_return(status: 200, body: settings.to_json, headers: {"Content-Type" => "application/json"})

    stub_request(:get, "https://connectapi.garmin.com/userprofile-service/userprofile/profile")
      .to_return(status: 200, body: profile.to_json, headers: {"Content-Type" => "application/json"})

    client = GarminConnect::Client.new(token_dir: dir)
    client.login
    client
  end
end
