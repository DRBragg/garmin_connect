# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe GarminConnect::API::BodyComposition do
  describe "#body_composition" do
    it "fetches body composition for a date range" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/weight-service/weight/dateRange")
        .with(query: { "startDate" => "2026-02-01", "endDate" => "2026-02-11" })
        .to_return(status: 200, body: '{"weight": 75.5}', headers: { "Content-Type" => "application/json" })

      result = client.body_composition("2026-02-01", "2026-02-11")

      expect(result).to eq("weight" => 75.5)
    end

    it "defaults end_date to start_date when only one date is given" do
      client = build_logged_in_client

      stub = stub_request(:get, "https://connectapi.garmin.com/weight-service/weight/dateRange")
        .with(query: { "startDate" => "2026-02-11", "endDate" => "2026-02-11" })
        .to_return(status: 200, body: '{"weight": 76.0}', headers: { "Content-Type" => "application/json" })

      client.body_composition("2026-02-11")

      expect(stub).to have_been_requested.once
    end
  end

  describe "#weigh_ins" do
    it "fetches weigh-ins for a date range with includeAll param" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/weight-service/weight/range/2026-02-01/2026-02-11")
        .with(query: { "includeAll" => "true" })
        .to_return(status: 200, body: '{"dailyWeightSummaries": [{"date": "2026-02-01"}]}', headers: { "Content-Type" => "application/json" })

      result = client.weigh_ins("2026-02-01", "2026-02-11")

      expect(result).to eq("dailyWeightSummaries" => [{ "date" => "2026-02-01" }])
    end
  end

  describe "#daily_weigh_ins" do
    it "fetches weigh-ins for a specific day with includeAll param" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/weight-service/weight/dayview/2026-02-11")
        .with(query: { "includeAll" => "true" })
        .to_return(status: 200, body: '{"dateWeightList": [{"weight": 75.5}]}', headers: { "Content-Type" => "application/json" })

      result = client.daily_weigh_ins("2026-02-11")

      expect(result).to eq("dateWeightList" => [{ "weight" => 75.5 }])
    end
  end

  describe "#add_weigh_in" do
    it "posts a weigh-in with the correct timestamp format and body" do
      client = build_logged_in_client

      stub = stub_request(:post, "https://connectapi.garmin.com/weight-service/user-weight")
        .with(body: {
          "dateTimestamp" => "2026-02-11T12:00:00.000",
          "gmtTimestamp" => "2026-02-11T12:00:00.000",
          "unitKey" => "kg",
          "sourceType" => "MANUAL",
          "value" => 75.5
        })
        .to_return(status: 200, body: '{}', headers: { "Content-Type" => "application/json" })

      client.add_weigh_in(75.5, date: "2026-02-11")

      expect(stub).to have_been_requested.once
    end

    it "accepts a custom unit_key" do
      client = build_logged_in_client

      stub = stub_request(:post, "https://connectapi.garmin.com/weight-service/user-weight")
        .with(body: {
          "dateTimestamp" => "2026-02-11T12:00:00.000",
          "gmtTimestamp" => "2026-02-11T12:00:00.000",
          "unitKey" => "lbs",
          "sourceType" => "MANUAL",
          "value" => 166.4
        })
        .to_return(status: 200, body: '{}', headers: { "Content-Type" => "application/json" })

      client.add_weigh_in(166.4, date: "2026-02-11", unit_key: "lbs")

      expect(stub).to have_been_requested.once
    end
  end

  describe "#add_weigh_in_with_timestamps" do
    it "posts a weigh-in with explicit timestamps" do
      client = build_logged_in_client

      stub = stub_request(:post, "https://connectapi.garmin.com/weight-service/user-weight")
        .with(body: {
          "dateTimestamp" => "2026-02-11T08:30:00.000",
          "gmtTimestamp" => "2026-02-11T14:30:00.000",
          "unitKey" => "kg",
          "sourceType" => "MANUAL",
          "value" => 75.5
        })
        .to_return(status: 200, body: '{}', headers: { "Content-Type" => "application/json" })

      client.add_weigh_in_with_timestamps(
        75.5,
        date_timestamp: "2026-02-11T08:30:00.000",
        gmt_timestamp: "2026-02-11T14:30:00.000"
      )

      expect(stub).to have_been_requested.once
    end
  end

  describe "#add_body_composition" do
    it "uploads a file via connection.upload" do
      client = build_logged_in_client

      allow(client.connection).to receive(:upload)
        .with("/upload-service/upload", file_path: "/path/to/body_comp.fit")
        .and_return({ "detailedImportResult" => { "successes" => [] } })

      result = client.add_body_composition("/path/to/body_comp.fit")

      expect(result).to eq("detailedImportResult" => { "successes" => [] })
      expect(client.connection).to have_received(:upload).once
    end
  end

  describe "#delete_weigh_in" do
    it "deletes a specific weigh-in by date and version" do
      client = build_logged_in_client

      stub = stub_request(:delete, "https://connectapi.garmin.com/weight-service/weight/2026-02-11/byversion/12345")
        .to_return(status: 204, body: "")

      client.delete_weigh_in("2026-02-11", 12345)

      expect(stub).to have_been_requested.once
    end
  end

  describe "#delete_weigh_ins" do
    it "deletes all weigh-ins for a date by fetching daily data first" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/weight-service/weight/dayview/2026-02-11")
        .with(query: { "includeAll" => "true" })
        .to_return(
          status: 200,
          body: '{"dateWeightList": [{"version": 1}, {"version": 2}]}',
          headers: { "Content-Type" => "application/json" }
        )

      delete_stub_1 = stub_request(:delete, "https://connectapi.garmin.com/weight-service/weight/2026-02-11/byversion/1")
        .to_return(status: 204, body: "")

      delete_stub_2 = stub_request(:delete, "https://connectapi.garmin.com/weight-service/weight/2026-02-11/byversion/2")
        .to_return(status: 204, body: "")

      client.delete_weigh_ins("2026-02-11")

      expect(delete_stub_1).to have_been_requested.once
      expect(delete_stub_2).to have_been_requested.once
    end

    it "does nothing when dateWeightList is empty" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/weight-service/weight/dayview/2026-02-11")
        .with(query: { "includeAll" => "true" })
        .to_return(
          status: 200,
          body: '{"dateWeightList": []}',
          headers: { "Content-Type" => "application/json" }
        )

      client.delete_weigh_ins("2026-02-11")

      expect(WebMock).not_to have_requested(:delete, /weight-service\/weight/)
    end

    it "falls back to samplePk when version is missing" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/weight-service/weight/dayview/2026-02-11")
        .with(query: { "includeAll" => "true" })
        .to_return(
          status: 200,
          body: '{"dateWeightList": [{"samplePk": 999}]}',
          headers: { "Content-Type" => "application/json" }
        )

      delete_stub = stub_request(:delete, "https://connectapi.garmin.com/weight-service/weight/2026-02-11/byversion/999")
        .to_return(status: 204, body: "")

      client.delete_weigh_ins("2026-02-11")

      expect(delete_stub).to have_been_requested.once
    end
  end

  describe "#hydration" do
    it "fetches daily hydration data for a given date" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/usersummary-service/usersummary/hydration/daily/2026-02-11",
        response_body: { "valueInML" => 2500 })

      result = client.hydration("2026-02-11")

      expect(result).to eq("valueInML" => 2500)
    end
  end

  describe "#log_hydration" do
    it "sends a PUT to log hydration intake" do
      client = build_logged_in_client

      stub = stub_request(:put, "https://connectapi.garmin.com/usersummary-service/usersummary/hydration/log")
        .to_return(status: 200, body: '{}', headers: { "Content-Type" => "application/json" })

      client.log_hydration(500, date: "2026-02-11")

      expect(stub).to have_been_requested.once
    end
  end

  describe "#blood_pressure" do
    it "fetches blood pressure data for a date range with includeAll param" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/bloodpressure-service/bloodpressure/range/2026-02-01/2026-02-11")
        .with(query: { "includeAll" => "true" })
        .to_return(status: 200, body: '{"measurementSummaries": []}', headers: { "Content-Type" => "application/json" })

      result = client.blood_pressure("2026-02-01", "2026-02-11")

      expect(result).to eq("measurementSummaries" => [])
    end
  end

  describe "#log_blood_pressure" do
    it "posts a blood pressure measurement without notes" do
      client = build_logged_in_client

      stub = stub_request(:post, "https://connectapi.garmin.com/bloodpressure-service/bloodpressure")
        .to_return(status: 200, body: '{}', headers: { "Content-Type" => "application/json" })

      client.log_blood_pressure(systolic: 120, diastolic: 80, pulse: 72, date: "2026-02-11")

      expect(stub).to have_been_requested.once
    end

    it "posts a blood pressure measurement with notes" do
      client = build_logged_in_client

      stub = stub_request(:post, "https://connectapi.garmin.com/bloodpressure-service/bloodpressure")
        .to_return(status: 200, body: '{}', headers: { "Content-Type" => "application/json" })

      client.log_blood_pressure(systolic: 130, diastolic: 85, pulse: 75, notes: "After exercise", date: "2026-02-11")

      expect(stub).to have_been_requested.once
    end
  end

  describe "#delete_blood_pressure" do
    it "deletes a blood pressure measurement by date and version" do
      client = build_logged_in_client

      stub = stub_request(:delete, "https://connectapi.garmin.com/bloodpressure-service/bloodpressure/2026-02-11/67890")
        .to_return(status: 204, body: "")

      client.delete_blood_pressure("2026-02-11", 67890)

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
