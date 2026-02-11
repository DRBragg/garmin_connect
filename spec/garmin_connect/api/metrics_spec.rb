# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe GarminConnect::API::Metrics do
  describe "#max_metrics" do
    it "fetches max metrics with the date repeated twice in the path" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/metrics-service/metrics/maxmet/daily/2026-02-11/2026-02-11",
        response_body: {"maxMetData" => [{"vo2Max" => 50.0}]})

      result = client.max_metrics("2026-02-11")

      expect(result).to eq("maxMetData" => [{"vo2Max" => 50.0}])
    end
  end

  describe "#training_readiness" do
    it "fetches training readiness for a given date" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/metrics-service/metrics/trainingreadiness/2026-02-11",
        response_body: [{"calendarDate" => "2026-02-11", "score" => 72}])

      result = client.training_readiness("2026-02-11")

      expect(result).to eq([{"calendarDate" => "2026-02-11", "score" => 72}])
    end
  end

  describe "#morning_training_readiness" do
    it "filters training_readiness results to only matching calendar dates" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/metrics-service/metrics/trainingreadiness/2026-02-11",
        response_body: [
          {"calendarDate" => "2026-02-11", "score" => 72},
          {"calendarDate" => "2026-02-10", "score" => 65}
        ])

      result = client.morning_training_readiness("2026-02-11")

      expect(result).to eq([{"calendarDate" => "2026-02-11", "score" => 72}])
    end

    it "returns the data as-is when the result is not an array" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/metrics-service/metrics/trainingreadiness/2026-02-11",
        response_body: {"error" => "no data"})

      result = client.morning_training_readiness("2026-02-11")

      expect(result).to eq("error" => "no data")
    end
  end

  describe "#training_status" do
    it "fetches aggregated training status for a given date" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/metrics-service/metrics/trainingstatus/aggregated/2026-02-11",
        response_body: {"trainingStatus" => "PRODUCTIVE"})

      result = client.training_status("2026-02-11")

      expect(result).to eq("trainingStatus" => "PRODUCTIVE")
    end
  end

  describe "#endurance_score" do
    it "fetches endurance score for a single date" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/metrics-service/metrics/endurancescore")
        .with(query: {"calendarDate" => "2026-02-11"})
        .to_return(status: 200, body: '{"overallScore": 68}', headers: {"Content-Type" => "application/json"})

      result = client.endurance_score("2026-02-11")

      expect(result).to eq("overallScore" => 68)
    end

    it "fetches endurance score stats for a date range" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/metrics-service/metrics/endurancescore/stats")
        .with(query: {"startDate" => "2026-01-01", "endDate" => "2026-02-11", "aggregation" => "weekly"})
        .to_return(status: 200, body: '[{"score": 65}, {"score": 70}]', headers: {"Content-Type" => "application/json"})

      result = client.endurance_score(start_date: "2026-01-01", end_date: "2026-02-11")

      expect(result).to eq([{"score" => 65}, {"score" => 70}])
    end
  end

  describe "#hill_score" do
    it "fetches hill score for a single date" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/metrics-service/metrics/hillscore")
        .with(query: {"calendarDate" => "2026-02-11"})
        .to_return(status: 200, body: '{"hillScore": 45}', headers: {"Content-Type" => "application/json"})

      result = client.hill_score("2026-02-11")

      expect(result).to eq("hillScore" => 45)
    end

    it "fetches hill score stats for a date range" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/metrics-service/metrics/hillscore/stats")
        .with(query: {"startDate" => "2026-01-01", "endDate" => "2026-02-11", "aggregation" => "daily"})
        .to_return(status: 200, body: '[{"hillScore": 40}, {"hillScore": 48}]', headers: {"Content-Type" => "application/json"})

      result = client.hill_score(start_date: "2026-01-01", end_date: "2026-02-11")

      expect(result).to eq([{"hillScore" => 40}, {"hillScore" => 48}])
    end
  end

  describe "#race_predictions" do
    it "fetches latest race predictions when no type is given" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/metrics-service/metrics/racepredictions/latest/TestUser",
        response_body: [{"raceType" => "5K", "predictedTime" => 1200}])

      result = client.race_predictions

      expect(result).to eq([{"raceType" => "5K", "predictedTime" => 1200}])
    end

    it "fetches race predictions for a specific type and date range" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/metrics-service/metrics/racepredictions/5K/TestUser")
        .with(query: {"fromCalendarDate" => "2026-01-01", "toCalendarDate" => "2026-02-11"})
        .to_return(status: 200, body: '[{"raceType": "5K", "predictedTime": 1180}]', headers: {"Content-Type" => "application/json"})

      result = client.race_predictions(type: "5K", start_date: "2026-01-01", end_date: "2026-02-11")

      expect(result).to eq([{"raceType" => "5K", "predictedTime" => 1180}])
    end
  end

  describe "#fitness_age" do
    it "fetches fitness age for a given date" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/fitnessage-service/fitnessage/2026-02-11",
        response_body: {"chronologicalAge" => 35, "fitnessAge" => 28.5})

      result = client.fitness_age("2026-02-11")

      expect(result).to eq("chronologicalAge" => 35, "fitnessAge" => 28.5)
    end
  end

  describe "#lactate_threshold" do
    it "fetches the latest lactate threshold" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/biometric-service/biometric/latestLactateThreshold",
        response_body: {"lactateThresholdHeartRate" => 165, "lactateThresholdSpeed" => 3.5})

      result = client.lactate_threshold

      expect(result).to eq("lactateThresholdHeartRate" => 165, "lactateThresholdSpeed" => 3.5)
    end
  end

  describe "#lactate_threshold_history" do
    it "makes three GET requests and returns a hash with speed, heart_rate, and power" do
      client = build_logged_in_client
      params = {"sport" => "RUNNING", "aggregation" => "daily", "aggregationStrategy" => "LATEST"}

      speed_stub = stub_request(:get, "https://connectapi.garmin.com/biometric-service/stats/lactateThresholdSpeed/range/2026-01-01/2026-02-11")
        .with(query: params)
        .to_return(status: 200, body: '[{"speed": 3.4}]', headers: {"Content-Type" => "application/json"})

      hr_stub = stub_request(:get, "https://connectapi.garmin.com/biometric-service/stats/lactateThresholdHeartRate/range/2026-01-01/2026-02-11")
        .with(query: params)
        .to_return(status: 200, body: '[{"heartRate": 162}]', headers: {"Content-Type" => "application/json"})

      power_stub = stub_request(:get, "https://connectapi.garmin.com/biometric-service/stats/functionalThresholdPower/range/2026-01-01/2026-02-11")
        .with(query: params)
        .to_return(status: 200, body: '[{"power": 250}]', headers: {"Content-Type" => "application/json"})

      result = client.lactate_threshold_history("2026-01-01", "2026-02-11")

      expect(result).to eq(
        "speed" => [{"speed" => 3.4}],
        "heart_rate" => [{"heartRate" => 162}],
        "power" => [{"power" => 250}]
      )
      expect(speed_stub).to have_been_requested.once
      expect(hr_stub).to have_been_requested.once
      expect(power_stub).to have_been_requested.once
    end
  end

  describe "#cycling_ftp" do
    it "fetches the latest cycling functional threshold power" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/biometric-service/biometric/latestFunctionalThresholdPower/CYCLING",
        response_body: {"functionalThresholdPower" => 260})

      result = client.cycling_ftp

      expect(result).to eq("functionalThresholdPower" => 260)
    end
  end

  describe "#daily_steps" do
    it "fetches daily steps for a short date range within a single chunk" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/usersummary-service/stats/steps/daily/2026-02-01/2026-02-11",
        response_body: [{"calendarDate" => "2026-02-01", "totalSteps" => 8000}, {"calendarDate" => "2026-02-11", "totalSteps" => 9500}])

      result = client.daily_steps("2026-02-01", "2026-02-11")

      expect(result).to eq([
        {"calendarDate" => "2026-02-01", "totalSteps" => 8000},
        {"calendarDate" => "2026-02-11", "totalSteps" => 9500}
      ])
    end
  end

  describe "#weekly_steps" do
    it "fetches weekly steps with default parameters" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/usersummary-service/stats/steps/weekly/2026-02-11/52",
        response_body: [{"week" => 1, "totalSteps" => 60000}])

      result = client.weekly_steps("2026-02-11")

      expect(result).to eq([{"week" => 1, "totalSteps" => 60000}])
    end
  end

  describe "#weekly_stress" do
    it "fetches weekly stress with default parameters" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/usersummary-service/stats/stress/weekly/2026-02-11/52",
        response_body: [{"week" => 1, "averageStress" => 35}])

      result = client.weekly_stress("2026-02-11")

      expect(result).to eq([{"week" => 1, "averageStress" => 35}])
    end
  end

  describe "#weekly_intensity_minutes" do
    it "fetches weekly intensity minutes for a date range" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/usersummary-service/stats/im/weekly/2026-01-01/2026-02-11",
        response_body: [{"week" => 1, "moderateMinutes" => 90, "vigorousMinutes" => 30}])

      result = client.weekly_intensity_minutes("2026-01-01", "2026-02-11")

      expect(result).to eq([{"week" => 1, "moderateMinutes" => 90, "vigorousMinutes" => 30}])
    end
  end

  private

  def build_logged_in_client
    dir = Dir.mktmpdir
    GarminConnect::Auth::TokenStore.save(dir, oauth1_token: build_oauth1_token, oauth2_token: build_oauth2_token)
    stub_request(:get, "https://connectapi.garmin.com/userprofile-service/userprofile/user-settings")
      .to_return(status: 200, body: '{"id": 123, "userData": {"measurementSystem": "metric"}}', headers: {"Content-Type" => "application/json"})
    stub_request(:get, "https://connectapi.garmin.com/userprofile-service/userprofile/profile")
      .to_return(status: 200, body: '{"displayName": "TestUser", "fullName": "Test User", "profileId": 123}', headers: {"Content-Type" => "application/json"})
    client = GarminConnect::Client.new(token_dir: dir)
    client.login
    client
  end
end
