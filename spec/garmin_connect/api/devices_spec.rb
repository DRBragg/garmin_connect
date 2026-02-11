# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe GarminConnect::API::Devices do
  describe "#devices" do
    it "returns the list of registered devices" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/device-service/deviceregistration/devices",
        response_body: [{ "deviceId" => 111, "deviceName" => "Forerunner 265" }, { "deviceId" => 222, "deviceName" => "Index Scale" }])

      result = client.devices

      expect(result).to eq([{ "deviceId" => 111, "deviceName" => "Forerunner 265" }, { "deviceId" => 222, "deviceName" => "Index Scale" }])
    end
  end

  describe "#device_settings" do
    it "returns settings for a given device" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/device-service/deviceservice/device-info/settings/111",
        response_body: { "alarms" => [{ "time" => "07:00" }], "displayOrientation" => "auto" })

      result = client.device_settings(111)

      expect(result).to eq("alarms" => [{ "time" => "07:00" }], "displayOrientation" => "auto")
    end
  end

  describe "#last_used_device" do
    it "returns the last used device" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/device-service/deviceservice/mylastused",
        response_body: { "deviceId" => 111, "lastUsedDeviceTime" => "2026-02-10" })

      result = client.last_used_device

      expect(result).to eq("deviceId" => 111, "lastUsedDeviceTime" => "2026-02-10")
    end
  end

  describe "#primary_training_device" do
    it "returns the primary training device" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/web-gateway/device-info/primary-training-device",
        response_body: { "deviceId" => 111, "isPrimary" => true })

      result = client.primary_training_device

      expect(result).to eq("deviceId" => 111, "isPrimary" => true)
    end
  end

  describe "#device_solar_data" do
    it "fetches solar data for a device with date range and singleDayView param" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/web-gateway/solar/111/2026-02-01/2026-02-10")
        .with(query: { "singleDayView" => "false" })
        .to_return(status: 200, body: '{"solarInput": 120}', headers: { "Content-Type" => "application/json" })

      result = client.device_solar_data(111, "2026-02-01", "2026-02-10")

      expect(result).to eq("solarInput" => 120)
    end

    it "passes singleDayView as true when single_day is set" do
      client = build_logged_in_client

      stub = stub_request(:get, "https://connectapi.garmin.com/web-gateway/solar/111/2026-02-10/2026-02-10")
        .with(query: { "singleDayView" => "true" })
        .to_return(status: 200, body: '{"solarInput": 60}', headers: { "Content-Type" => "application/json" })

      client.device_solar_data(111, "2026-02-10", "2026-02-10", single_day: true)

      expect(stub).to have_been_requested.once
    end
  end

  describe "#device_alarms" do
    it "returns device and alarm pairs for devices that have alarms" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/device-service/deviceregistration/devices",
        response_body: [{ "deviceId" => 111 }, { "deviceId" => 222 }])

      stub_garmin_api(:get, "/device-service/deviceservice/device-info/settings/111",
        response_body: { "alarms" => [{ "time" => "07:00" }] })

      stub_garmin_api(:get, "/device-service/deviceservice/device-info/settings/222",
        response_body: { "brightness" => 80 })

      result = client.device_alarms

      expect(result).to eq([
        { "device" => { "deviceId" => 111 }, "alarms" => [{ "time" => "07:00" }] }
      ])
    end

    it "returns an empty array when devices returns a non-array" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/device-service/deviceregistration/devices",
        response_body: { "error" => "not found" })

      result = client.device_alarms

      expect(result).to eq([])
    end
  end

  describe "#gear" do
    it "returns gear filtered by user profile pk" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/gear-service/gear/filterGear")
        .with(query: { "userProfilePk" => "123" })
        .to_return(status: 200, body: '[{"uuid": "abc-123", "gearName": "Running Shoes"}]', headers: { "Content-Type" => "application/json" })

      result = client.gear

      expect(result).to eq([{ "uuid" => "abc-123", "gearName" => "Running Shoes" }])
    end
  end

  describe "#activity_gear" do
    it "returns gear linked to a specific activity" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/gear-service/gear/filterGear")
        .with(query: { "activityId" => "99999" })
        .to_return(status: 200, body: '[{"uuid": "abc-123", "gearName": "Running Shoes"}]', headers: { "Content-Type" => "application/json" })

      result = client.activity_gear(99999)

      expect(result).to eq([{ "uuid" => "abc-123", "gearName" => "Running Shoes" }])
    end
  end

  describe "#gear_stats" do
    it "returns stats for a specific gear item" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/gear-service/gear/stats/abc-123",
        response_body: { "totalDistance" => 500.0, "totalActivities" => 42 })

      result = client.gear_stats("abc-123")

      expect(result).to eq("totalDistance" => 500.0, "totalActivities" => 42)
    end
  end

  describe "#gear_defaults" do
    it "returns default gear for activity types using user profile pk in path" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/gear-service/gear/user/123/activityTypes",
        response_body: [{ "activityType" => "running", "gearUuid" => "abc-123" }])

      result = client.gear_defaults

      expect(result).to eq([{ "activityType" => "running", "gearUuid" => "abc-123" }])
    end
  end

  describe "#set_gear_default" do
    it "sends a PUT request when default is true" do
      client = build_logged_in_client

      stub = stub_request(:put, "https://connectapi.garmin.com/gear-service/gear/abc-123/activityType/running/default/true")
        .to_return(status: 200, body: '{}', headers: { "Content-Type" => "application/json" })

      client.set_gear_default("abc-123", "running", default: true)

      expect(stub).to have_been_requested.once
    end

    it "sends a DELETE request when default is false" do
      client = build_logged_in_client

      stub = stub_request(:delete, "https://connectapi.garmin.com/gear-service/gear/abc-123/activityType/running")
        .to_return(status: 200, body: '{}', headers: { "Content-Type" => "application/json" })

      client.set_gear_default("abc-123", "running", default: false)

      expect(stub).to have_been_requested.once
    end
  end

  describe "#link_gear" do
    it "sends a PUT request to link gear to an activity" do
      client = build_logged_in_client

      stub = stub_request(:put, "https://connectapi.garmin.com/gear-service/gear/link/abc-123/activity/99999")
        .to_return(status: 200, body: '{}', headers: { "Content-Type" => "application/json" })

      client.link_gear("abc-123", 99999)

      expect(stub).to have_been_requested.once
    end
  end

  describe "#unlink_gear" do
    it "sends a PUT request to unlink gear from an activity" do
      client = build_logged_in_client

      stub = stub_request(:put, "https://connectapi.garmin.com/gear-service/gear/unlink/abc-123/activity/99999")
        .to_return(status: 200, body: '{}', headers: { "Content-Type" => "application/json" })

      client.unlink_gear("abc-123", 99999)

      expect(stub).to have_been_requested.once
    end
  end

  describe "#gear_activities" do
    it "returns activities for a gear item with default limit" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/activitylist-service/activities/abc-123/gear")
        .with(query: { "start" => "0", "limit" => "20" })
        .to_return(status: 200, body: '[{"activityId": 1}, {"activityId": 2}]', headers: { "Content-Type" => "application/json" })

      result = client.gear_activities("abc-123")

      expect(result).to eq([{ "activityId" => 1 }, { "activityId" => 2 }])
    end

    it "passes a custom limit parameter" do
      client = build_logged_in_client

      stub = stub_request(:get, "https://connectapi.garmin.com/activitylist-service/activities/abc-123/gear")
        .with(query: { "start" => "0", "limit" => "5" })
        .to_return(status: 200, body: '[{"activityId": 1}]', headers: { "Content-Type" => "application/json" })

      client.gear_activities("abc-123", limit: 5)

      expect(stub).to have_been_requested.once
    end
  end

  private

  def build_logged_in_client
    dir = Dir.mktmpdir
    GarminConnect::Auth::TokenStore.save(dir, oauth1_token: build_oauth1_token, oauth2_token: build_oauth2_token)
    stub_request(:get, "https://connectapi.garmin.com/userprofile-service/userprofile/user-settings")
      .to_return(status: 200, body: '{"id": 123, "userData": {"measurementSystem": "metric"}}', headers: { "Content-Type" => "application/json" })
    stub_request(:get, "https://connectapi.garmin.com/userprofile-service/userprofile/profile")
      .to_return(status: 200, body: '{"displayName": "TestUser", "fullName": "Test User", "profileId": 123}', headers: { "Content-Type" => "application/json" })
    client = GarminConnect::Client.new(token_dir: dir)
    client.login
    client
  end
end
