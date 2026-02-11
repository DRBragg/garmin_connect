# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe GarminConnect::API::Health do
  describe "#daily_summary" do
    it "fetches the daily summary for a given date" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/usersummary-service/usersummary/daily/TestUser")
        .with(query: { "calendarDate" => "2026-02-11" })
        .to_return(status: 200, body: '{"totalSteps": 8500}', headers: { "Content-Type" => "application/json" })

      result = client.daily_summary("2026-02-11")

      expect(result).to eq("totalSteps" => 8500)
    end
  end

  describe "#stats" do
    it "is an alias for daily_summary and hits the same endpoint" do
      client = build_logged_in_client

      stub = stub_request(:get, "https://connectapi.garmin.com/usersummary-service/usersummary/daily/TestUser")
        .with(query: { "calendarDate" => "2026-02-11" })
        .to_return(status: 200, body: '{"totalSteps": 9000}', headers: { "Content-Type" => "application/json" })

      result = client.stats("2026-02-11")

      expect(result).to eq("totalSteps" => 9000)
      expect(stub).to have_been_requested.once
    end
  end

  describe "#stats_and_body" do
    it "returns a hash with stats and body_composition data" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/usersummary-service/usersummary/daily/TestUser")
        .with(query: { "calendarDate" => "2026-02-11" })
        .to_return(status: 200, body: '{"totalSteps": 7000}', headers: { "Content-Type" => "application/json" })

      stub_request(:get, "https://connectapi.garmin.com/weight-service/weight/dateRange")
        .with(query: { "startDate" => "2026-02-11", "endDate" => "2026-02-11" })
        .to_return(status: 200, body: '{"weight": 75.5}', headers: { "Content-Type" => "application/json" })

      result = client.stats_and_body("2026-02-11")

      expect(result).to eq(
        "stats" => { "totalSteps" => 7000 },
        "body_composition" => { "weight" => 75.5 }
      )
    end
  end

  describe "#heart_rates" do
    it "fetches daily heart rate data for a given date" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/wellness-service/wellness/dailyHeartRate/TestUser")
        .with(query: { "date" => "2026-02-11" })
        .to_return(status: 200, body: '{"restingHeartRate": 62}', headers: { "Content-Type" => "application/json" })

      result = client.heart_rates("2026-02-11")

      expect(result).to eq("restingHeartRate" => 62)
    end
  end

  describe "#resting_heart_rate" do
    it "fetches resting heart rate for a date range" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/userstats-service/wellness/daily/TestUser")
        .with(query: { "fromDate" => "2026-02-01", "untilDate" => "2026-02-11", "metricId" => "60" })
        .to_return(status: 200, body: '{"allMetrics": [{"metricsMap": {"WELLNESS_RESTING_HEART_RATE": [60]}}]}', headers: { "Content-Type" => "application/json" })

      result = client.resting_heart_rate("2026-02-01", "2026-02-11")

      expect(result["allMetrics"]).to be_an(Array)
    end

    it "defaults end_date to start_date when only one date is given" do
      client = build_logged_in_client

      stub = stub_request(:get, "https://connectapi.garmin.com/userstats-service/wellness/daily/TestUser")
        .with(query: { "fromDate" => "2026-02-11", "untilDate" => "2026-02-11", "metricId" => "60" })
        .to_return(status: 200, body: '{}', headers: { "Content-Type" => "application/json" })

      client.resting_heart_rate("2026-02-11")

      expect(stub).to have_been_requested.once
    end
  end

  describe "#hrv" do
    it "fetches HRV data for a given date" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/hrv-service/hrv/2026-02-11", response_body: { "hrvSummary" => { "weeklyAvg" => 45 } })

      result = client.hrv("2026-02-11")

      expect(result).to eq("hrvSummary" => { "weeklyAvg" => 45 })
    end
  end

  describe "#sleep_data" do
    it "fetches daily sleep data for a given date" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/wellness-service/wellness/dailySleepData/TestUser")
        .with(query: { "date" => "2026-02-11", "nonSleepBufferMinutes" => "60" })
        .to_return(status: 200, body: '{"sleepTimeSeconds": 28800}', headers: { "Content-Type" => "application/json" })

      result = client.sleep_data("2026-02-11")

      expect(result).to eq("sleepTimeSeconds" => 28800)
    end
  end

  describe "#stress" do
    it "fetches daily stress data for a given date" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/wellness-service/wellness/dailyStress/2026-02-11", response_body: { "overallStressLevel" => 35 })

      result = client.stress("2026-02-11")

      expect(result).to eq("overallStressLevel" => 35)
    end
  end

  describe "#body_battery" do
    it "fetches body battery reports for a date range" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/wellness-service/wellness/bodyBattery/reports/daily")
        .with(query: { "startDate" => "2026-02-01", "endDate" => "2026-02-11" })
        .to_return(status: 200, body: '[{"date": "2026-02-01", "charged": 65}]', headers: { "Content-Type" => "application/json" })

      result = client.body_battery("2026-02-01", "2026-02-11")

      expect(result).to be_an(Array)
      expect(result.first["charged"]).to eq(65)
    end

    it "defaults both dates to the same value when only start_date is given" do
      client = build_logged_in_client

      stub = stub_request(:get, "https://connectapi.garmin.com/wellness-service/wellness/bodyBattery/reports/daily")
        .with(query: { "startDate" => "2026-02-11", "endDate" => "2026-02-11" })
        .to_return(status: 200, body: '[]', headers: { "Content-Type" => "application/json" })

      client.body_battery("2026-02-11")

      expect(stub).to have_been_requested.once
    end
  end

  describe "#body_battery_events" do
    it "fetches body battery events for a given date" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/wellness-service/wellness/bodyBattery/events/2026-02-11", response_body: { "events" => [] })

      result = client.body_battery_events("2026-02-11")

      expect(result).to eq("events" => [])
    end
  end

  describe "#steps_data" do
    it "fetches daily summary chart data for a given date" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/wellness-service/wellness/dailySummaryChart/TestUser")
        .with(query: { "date" => "2026-02-11" })
        .to_return(status: 200, body: '[{"startGMT": "2026-02-11T00:00:00.0", "steps": 500}]', headers: { "Content-Type" => "application/json" })

      result = client.steps_data("2026-02-11")

      expect(result).to be_an(Array)
      expect(result.first["steps"]).to eq(500)
    end
  end

  describe "#floors" do
    it "fetches floors chart data for a given date" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/wellness-service/wellness/floorsChartData/daily/2026-02-11", response_body: { "floorsTotalAscended" => 12 })

      result = client.floors("2026-02-11")

      expect(result).to eq("floorsTotalAscended" => 12)
    end
  end

  describe "#respiration" do
    it "fetches daily respiration data for a given date" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/wellness-service/wellness/daily/respiration/2026-02-11", response_body: { "avgWakingRespirationValue" => 16.5 })

      result = client.respiration("2026-02-11")

      expect(result).to eq("avgWakingRespirationValue" => 16.5)
    end
  end

  describe "#spo2" do
    it "fetches daily SpO2 data for a given date" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/wellness-service/wellness/daily/spo2/2026-02-11", response_body: { "averageSPO2" => 96 })

      result = client.spo2("2026-02-11")

      expect(result).to eq("averageSPO2" => 96)
    end
  end

  describe "#intensity_minutes" do
    it "fetches daily intensity minutes for a given date" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/wellness-service/wellness/daily/im/2026-02-11", response_body: { "weeklyModerate" => 90, "weeklyVigorous" => 30 })

      result = client.intensity_minutes("2026-02-11")

      expect(result).to eq("weeklyModerate" => 90, "weeklyVigorous" => 30)
    end
  end

  describe "#daily_events" do
    it "fetches daily wellness events for a given date" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/wellness-service/wellness/dailyEvents")
        .with(query: { "calendarDate" => "2026-02-11" })
        .to_return(status: 200, body: '{"events": [{"eventType": "sleep"}]}', headers: { "Content-Type" => "application/json" })

      result = client.daily_events("2026-02-11")

      expect(result["events"]).to be_an(Array)
    end
  end

  describe "#request_reload" do
    it "sends a POST to request epoch data reload for a given date" do
      client = build_logged_in_client

      stub = stub_request(:post, "https://connectapi.garmin.com/wellness-service/wellness/epoch/request/2026-02-11")
        .to_return(status: 200, body: '{}', headers: { "Content-Type" => "application/json" })

      client.request_reload("2026-02-11")

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
