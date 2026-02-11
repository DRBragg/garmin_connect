# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "tempfile"

RSpec.describe GarminConnect::API::Activities do
  describe "#activities" do
    it "returns activities with default parameters" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/activitylist-service/activities/search/activities")
        .with(query: { "start" => "0", "limit" => "20", "sortOrder" => "desc" })
        .to_return(status: 200, body: '[{"activityId": 1}, {"activityId": 2}]', headers: { "Content-Type" => "application/json" })

      result = client.activities

      expect(result).to eq([{ "activityId" => 1 }, { "activityId" => 2 }])
    end

    it "passes activity_type when provided" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/activitylist-service/activities/search/activities")
        .with(query: { "start" => "0", "limit" => "20", "activityType" => "running", "sortOrder" => "desc" })
        .to_return(status: 200, body: '[{"activityId": 3, "activityType": "running"}]', headers: { "Content-Type" => "application/json" })

      result = client.activities(activity_type: "running")

      expect(result).to eq([{ "activityId" => 3, "activityType" => "running" }])
    end
  end

  describe "#activities_by_date" do
    it "returns activities within the given date range" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/activitylist-service/activities/search/activities")
        .with(query: { "startDate" => "2026-01-01", "endDate" => "2026-01-31", "start" => "0", "limit" => "100" })
        .to_return(status: 200, body: '[{"activityId": 10}]', headers: { "Content-Type" => "application/json" })

      result = client.activities_by_date("2026-01-01", "2026-01-31")

      expect(result).to eq([{ "activityId" => 10 }])
    end

    it "passes activity_type when provided" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/activitylist-service/activities/search/activities")
        .with(query: { "startDate" => "2026-01-01", "endDate" => "2026-01-31", "start" => "0", "limit" => "100", "activityType" => "cycling" })
        .to_return(status: 200, body: '[{"activityId": 11, "activityType": "cycling"}]', headers: { "Content-Type" => "application/json" })

      result = client.activities_by_date("2026-01-01", "2026-01-31", activity_type: "cycling")

      expect(result).to eq([{ "activityId" => 11, "activityType" => "cycling" }])
    end
  end

  describe "#activity_count" do
    it "returns the activity count" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/activitylist-service/activities/count",
        response_body: { "totalActivities" => 42 })

      result = client.activity_count

      expect(result).to eq("totalActivities" => 42)
    end
  end

  describe "#last_activity" do
    it "returns the first element from a single-item activities request" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/activitylist-service/activities/search/activities")
        .with(query: { "start" => "0", "limit" => "1", "sortOrder" => "desc" })
        .to_return(status: 200, body: '[{"activityId": 99, "activityName": "Morning Run"}]', headers: { "Content-Type" => "application/json" })

      result = client.last_activity

      expect(result).to eq("activityId" => 99, "activityName" => "Morning Run")
    end
  end

  describe "#activity" do
    it "returns the activity for the given ID" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/activity-service/activity/12345",
        response_body: { "activityId" => 12345, "activityName" => "Afternoon Ride" })

      result = client.activity(12345)

      expect(result).to eq("activityId" => 12345, "activityName" => "Afternoon Ride")
    end
  end

  describe "#activity_details" do
    it "returns activity details with default chart and polyline sizes" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/activity-service/activity/12345/details")
        .with(query: { "maxChartSize" => "2000", "maxPolylineSize" => "4000" })
        .to_return(status: 200, body: '{"activityId": 12345, "metrics": []}', headers: { "Content-Type" => "application/json" })

      result = client.activity_details(12345)

      expect(result).to eq("activityId" => 12345, "metrics" => [])
    end

    it "passes custom chart and polyline sizes" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/activity-service/activity/12345/details")
        .with(query: { "maxChartSize" => "500", "maxPolylineSize" => "1000" })
        .to_return(status: 200, body: '{"activityId": 12345}', headers: { "Content-Type" => "application/json" })

      result = client.activity_details(12345, max_chart_size: 500, max_polyline_size: 1000)

      expect(result).to eq("activityId" => 12345)
    end
  end

  describe "#activity_splits" do
    it "returns splits for the given activity" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/activity-service/activity/12345/splits",
        response_body: { "lapDTOs" => [{ "distance" => 1000 }] })

      result = client.activity_splits(12345)

      expect(result).to eq("lapDTOs" => [{ "distance" => 1000 }])
    end
  end

  describe "#activity_typed_splits" do
    it "returns typed splits for the given activity" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/activity-service/activity/12345/typedsplits",
        response_body: { "typedSplits" => [] })

      result = client.activity_typed_splits(12345)

      expect(result).to eq("typedSplits" => [])
    end
  end

  describe "#activity_split_summaries" do
    it "returns split summaries for the given activity" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/activity-service/activity/12345/split_summaries",
        response_body: { "splitSummaries" => [] })

      result = client.activity_split_summaries(12345)

      expect(result).to eq("splitSummaries" => [])
    end
  end

  describe "#activity_weather" do
    it "returns weather data for the given activity" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/activity-service/activity/12345/weather",
        response_body: { "temp" => 22, "weatherTypeDTO" => { "desc" => "Sunny" } })

      result = client.activity_weather(12345)

      expect(result).to eq("temp" => 22, "weatherTypeDTO" => { "desc" => "Sunny" })
    end
  end

  describe "#activity_hr_zones" do
    it "returns heart rate zones for the given activity" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/activity-service/activity/12345/hrTimeInZones",
        response_body: { "zones" => [{ "zone" => 1, "seconds" => 300 }] })

      result = client.activity_hr_zones(12345)

      expect(result).to eq("zones" => [{ "zone" => 1, "seconds" => 300 }])
    end
  end

  describe "#activity_power_zones" do
    it "returns power zones for the given activity" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/activity-service/activity/12345/powerTimeInZones",
        response_body: { "zones" => [{ "zone" => 1, "watts" => 150 }] })

      result = client.activity_power_zones(12345)

      expect(result).to eq("zones" => [{ "zone" => 1, "watts" => 150 }])
    end
  end

  describe "#activity_exercise_sets" do
    it "returns exercise sets for the given activity" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/activity-service/activity/12345/exerciseSets",
        response_body: { "exerciseSets" => [{ "setType" => "ACTIVE" }] })

      result = client.activity_exercise_sets(12345)

      expect(result).to eq("exerciseSets" => [{ "setType" => "ACTIVE" }])
    end
  end

  describe "#activity_types" do
    it "returns the list of activity types" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/activity-service/activity/activityTypes",
        response_body: [{ "typeId" => 1, "typeKey" => "running" }, { "typeId" => 2, "typeKey" => "cycling" }])

      result = client.activity_types

      expect(result).to eq([{ "typeId" => 1, "typeKey" => "running" }, { "typeId" => 2, "typeKey" => "cycling" }])
    end
  end

  describe "#heart_rate_activities" do
    it "returns heart rate data for the given date" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/mobile-gateway/heartRate/forDate/2026-02-01",
        response_body: { "heartRateValues" => [[1000, 72], [2000, 75]] })

      result = client.heart_rate_activities("2026-02-01")

      expect(result).to eq("heartRateValues" => [[1000, 72], [2000, 75]])
    end
  end

  describe "#create_activity" do
    it "posts the activity payload and returns the created activity" do
      client = build_logged_in_client
      payload = { "activityName" => "Test Run", "activityTypeDTO" => { "typeKey" => "running" } }

      stub_request(:post, "https://connectapi.garmin.com/activity-service/activity")
        .to_return(status: 200, body: '{"activityId": 99999, "activityName": "Test Run"}', headers: { "Content-Type" => "application/json" })

      result = client.create_activity(payload)

      expect(result).to eq("activityId" => 99999, "activityName" => "Test Run")
    end
  end

  describe "#rename_activity" do
    it "puts the new name and returns the updated activity" do
      client = build_logged_in_client

      stub_request(:put, "https://connectapi.garmin.com/activity-service/activity/12345")
        .to_return(status: 200, body: '{"activityId": 12345, "activityName": "Renamed Run"}', headers: { "Content-Type" => "application/json" })

      result = client.rename_activity(12345, "Renamed Run")

      expect(result).to eq("activityId" => 12345, "activityName" => "Renamed Run")
    end
  end

  describe "#update_activity_type" do
    it "puts the new activity type and returns the updated activity" do
      client = build_logged_in_client
      activity_type = { "typeKey" => "cycling", "typeId" => 2 }

      stub_request(:put, "https://connectapi.garmin.com/activity-service/activity/12345")
        .to_return(status: 200, body: '{"activityId": 12345, "activityTypeDTO": {"typeKey": "cycling"}}', headers: { "Content-Type" => "application/json" })

      result = client.update_activity_type(12345, activity_type)

      expect(result).to eq("activityId" => 12345, "activityTypeDTO" => { "typeKey" => "cycling" })
    end
  end

  describe "#delete_activity" do
    it "deletes the activity and returns nil for a 204 response" do
      client = build_logged_in_client

      stub_request(:delete, "https://connectapi.garmin.com/activity-service/activity/12345")
        .to_return(status: 204, body: "")

      result = client.delete_activity(12345)

      expect(result).to be_nil
    end
  end

  describe "#download_activity" do
    it "downloads the original format file" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/download-service/files/activity/12345")
        .to_return(status: 200, body: "fake-fit-file-content")

      result = client.download_activity(12345, format: :original)

      expect(result).to eq("fake-fit-file-content")
    end

    it "downloads the GPX format file" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/download-service/export/gpx/activity/12345")
        .to_return(status: 200, body: "<gpx>fake gpx data</gpx>")

      result = client.download_activity(12345, format: :gpx)

      expect(result).to eq("<gpx>fake gpx data</gpx>")
    end

    it "raises ArgumentError for an unknown format" do
      client = build_logged_in_client

      expect { client.download_activity(12345, format: :pdf) }.to raise_error(ArgumentError, /Unknown format: pdf/)
    end
  end

  describe "#upload_activity" do
    it "uploads a file and returns the parsed response" do
      client = build_logged_in_client

      tmpfile = Tempfile.new(["test_activity", ".fit"])
      tmpfile.write("fake fit data")
      tmpfile.close

      allow(client.connection).to receive(:upload)
        .with("/upload-service/upload", file_path: tmpfile.path)
        .and_return({ "detailedImportResult" => { "successes" => [{ "internalId" => 12345 }] } })

      result = client.upload_activity(tmpfile.path)

      expect(result).to eq("detailedImportResult" => { "successes" => [{ "internalId" => 12345 }] })
    ensure
      tmpfile&.unlink
    end
  end

  describe "#progress_summary" do
    it "returns the fitness stats with default metric" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/fitnessstats-service/activity")
        .with(query: { "startDate" => "2026-01-01", "endDate" => "2026-01-31", "aggregation" => "lifetime", "groupByParentActivityType" => "true", "metric" => "distance" })
        .to_return(status: 200, body: '{"allMetrics": {"distance": 100.0}}', headers: { "Content-Type" => "application/json" })

      result = client.progress_summary("2026-01-01", "2026-01-31")

      expect(result).to eq("allMetrics" => { "distance" => 100.0 })
    end

    it "passes a custom metric parameter" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/fitnessstats-service/activity")
        .with(query: { "startDate" => "2026-01-01", "endDate" => "2026-01-31", "aggregation" => "lifetime", "groupByParentActivityType" => "true", "metric" => "duration" })
        .to_return(status: 200, body: '{"allMetrics": {"duration": 3600}}', headers: { "Content-Type" => "application/json" })

      result = client.progress_summary("2026-01-01", "2026-01-31", metric: "duration")

      expect(result).to eq("allMetrics" => { "duration" => 3600 })
    end
  end

  private

  def build_logged_in_client
    dir = Dir.mktmpdir

    GarminConnect::Auth::TokenStore.save(dir,
      oauth1_token: build_oauth1_token,
      oauth2_token: build_oauth2_token)

    stub_request(:get, "https://connectapi.garmin.com/userprofile-service/userprofile/user-settings")
      .to_return(status: 200, body: '{"id": 123, "userData": {"measurementSystem": "metric"}}', headers: { "Content-Type" => "application/json" })

    stub_request(:get, "https://connectapi.garmin.com/userprofile-service/userprofile/profile")
      .to_return(status: 200, body: '{"displayName": "TestUser", "fullName": "Test User", "profileId": 123}', headers: { "Content-Type" => "application/json" })

    client = GarminConnect::Client.new(token_dir: dir)
    client.login
    client
  end
end
