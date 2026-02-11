# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe GarminConnect::API::Workouts do
  describe "#workouts" do
    it "returns workouts with default parameters" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/workout-service/workouts")
        .with(query: { "start" => "0", "limit" => "20" })
        .to_return(status: 200, body: '[{"workoutId": 1}, {"workoutId": 2}]', headers: { "Content-Type" => "application/json" })

      result = client.workouts

      expect(result).to eq([{ "workoutId" => 1 }, { "workoutId" => 2 }])
    end

    it "passes custom start and limit parameters" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/workout-service/workouts")
        .with(query: { "start" => "10", "limit" => "5" })
        .to_return(status: 200, body: '[{"workoutId": 3}]', headers: { "Content-Type" => "application/json" })

      result = client.workouts(start: 10, limit: 5)

      expect(result).to eq([{ "workoutId" => 3 }])
    end
  end

  describe "#workout" do
    it "returns the workout for the given ID" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/workout-service/workout/42",
        response_body: { "workoutId" => 42, "workoutName" => "Easy Run" })

      result = client.workout(42)

      expect(result).to eq("workoutId" => 42, "workoutName" => "Easy Run")
    end
  end

  describe "#download_workout" do
    it "downloads the FIT file as raw bytes" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/workout-service/workout/FIT/42")
        .to_return(status: 200, body: "fake-fit-data")

      result = client.download_workout(42)

      expect(result).to eq("fake-fit-data")
    end
  end

  describe "#create_workout" do
    it "posts the workout payload and returns the created workout" do
      client = build_logged_in_client
      payload = { "workoutName" => "Custom Workout", "sportType" => { "sportTypeId" => 1, "sportTypeKey" => "running" } }

      stub_request(:post, "https://connectapi.garmin.com/workout-service/workout")
        .to_return(status: 200, body: '{"workoutId": 100, "workoutName": "Custom Workout"}', headers: { "Content-Type" => "application/json" })

      result = client.create_workout(payload)

      expect(result).to eq("workoutId" => 100, "workoutName" => "Custom Workout")
    end
  end

  describe "#scheduled_workout" do
    it "returns the scheduled workout for the given ID" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/workout-service/schedule/55",
        response_body: { "scheduledWorkoutId" => 55, "date" => "2026-03-01" })

      result = client.scheduled_workout(55)

      expect(result).to eq("scheduledWorkoutId" => 55, "date" => "2026-03-01")
    end
  end

  describe "#create_running_workout" do
    it "posts a running workout with sportTypeId 1 and sportTypeKey running" do
      client = build_logged_in_client

      stub = stub_request(:post, "https://connectapi.garmin.com/workout-service/workout")
        .with { |request|
          body = JSON.parse(request.body)
          body["workoutName"] == "Morning Run" &&
            body["sportType"] == { "sportTypeId" => 1, "sportTypeKey" => "running" } &&
            body["workoutSegments"][0]["sportType"] == { "sportTypeId" => 1, "sportTypeKey" => "running" } &&
            body["workoutSegments"][0]["segmentOrder"] == 1 &&
            !body.key?("description")
        }
        .to_return(status: 200, body: '{"workoutId": 200, "workoutName": "Morning Run"}', headers: { "Content-Type" => "application/json" })

      result = client.create_running_workout("Morning Run")

      expect(stub).to have_been_requested.once
      expect(result).to eq("workoutId" => 200, "workoutName" => "Morning Run")
    end

    it "includes description when provided" do
      client = build_logged_in_client

      stub = stub_request(:post, "https://connectapi.garmin.com/workout-service/workout")
        .with { |request|
          body = JSON.parse(request.body)
          body["workoutName"] == "Tempo Run" &&
            body["description"] == "A steady tempo effort" &&
            body["sportType"] == { "sportTypeId" => 1, "sportTypeKey" => "running" }
        }
        .to_return(status: 200, body: '{"workoutId": 201, "workoutName": "Tempo Run"}', headers: { "Content-Type" => "application/json" })

      result = client.create_running_workout("Tempo Run", description: "A steady tempo effort")

      expect(stub).to have_been_requested.once
      expect(result).to eq("workoutId" => 201, "workoutName" => "Tempo Run")
    end

    it "passes workout steps through to the payload" do
      client = build_logged_in_client
      steps = [{ "stepOrder" => 1, "stepType" => { "stepTypeId" => 3, "stepTypeKey" => "interval" } }]

      stub = stub_request(:post, "https://connectapi.garmin.com/workout-service/workout")
        .with { |request|
          body = JSON.parse(request.body)
          body["workoutSegments"][0]["workoutSteps"] == steps
        }
        .to_return(status: 200, body: '{"workoutId": 202}', headers: { "Content-Type" => "application/json" })

      client.create_running_workout("Intervals", steps: steps)

      expect(stub).to have_been_requested.once
    end
  end

  describe "#create_cycling_workout" do
    it "posts a cycling workout with sportTypeId 2 and sportTypeKey cycling" do
      client = build_logged_in_client

      stub = stub_request(:post, "https://connectapi.garmin.com/workout-service/workout")
        .with { |request|
          body = JSON.parse(request.body)
          body["workoutName"] == "Sweet Spot" &&
            body["sportType"] == { "sportTypeId" => 2, "sportTypeKey" => "cycling" } &&
            body["workoutSegments"][0]["sportType"] == { "sportTypeId" => 2, "sportTypeKey" => "cycling" }
        }
        .to_return(status: 200, body: '{"workoutId": 300, "workoutName": "Sweet Spot"}', headers: { "Content-Type" => "application/json" })

      result = client.create_cycling_workout("Sweet Spot")

      expect(stub).to have_been_requested.once
      expect(result).to eq("workoutId" => 300, "workoutName" => "Sweet Spot")
    end
  end

  describe "#create_swimming_workout" do
    it "posts a swimming workout with sportTypeId 5 and sportTypeKey swimming" do
      client = build_logged_in_client

      stub = stub_request(:post, "https://connectapi.garmin.com/workout-service/workout")
        .with { |request|
          body = JSON.parse(request.body)
          body["workoutName"] == "Pool Drills" &&
            body["sportType"] == { "sportTypeId" => 5, "sportTypeKey" => "swimming" } &&
            body["workoutSegments"][0]["sportType"] == { "sportTypeId" => 5, "sportTypeKey" => "swimming" }
        }
        .to_return(status: 200, body: '{"workoutId": 400, "workoutName": "Pool Drills"}', headers: { "Content-Type" => "application/json" })

      result = client.create_swimming_workout("Pool Drills")

      expect(stub).to have_been_requested.once
      expect(result).to eq("workoutId" => 400, "workoutName" => "Pool Drills")
    end
  end

  describe "#create_walking_workout" do
    it "posts a walking workout with sportTypeId 9 and sportTypeKey walking" do
      client = build_logged_in_client

      stub = stub_request(:post, "https://connectapi.garmin.com/workout-service/workout")
        .with { |request|
          body = JSON.parse(request.body)
          body["workoutName"] == "Evening Walk" &&
            body["sportType"] == { "sportTypeId" => 9, "sportTypeKey" => "walking" } &&
            body["workoutSegments"][0]["sportType"] == { "sportTypeId" => 9, "sportTypeKey" => "walking" }
        }
        .to_return(status: 200, body: '{"workoutId": 500, "workoutName": "Evening Walk"}', headers: { "Content-Type" => "application/json" })

      result = client.create_walking_workout("Evening Walk")

      expect(stub).to have_been_requested.once
      expect(result).to eq("workoutId" => 500, "workoutName" => "Evening Walk")
    end
  end

  describe "#create_hiking_workout" do
    it "posts a hiking workout with sportTypeId 3 and sportTypeKey hiking" do
      client = build_logged_in_client

      stub = stub_request(:post, "https://connectapi.garmin.com/workout-service/workout")
        .with { |request|
          body = JSON.parse(request.body)
          body["workoutName"] == "Trail Hike" &&
            body["sportType"] == { "sportTypeId" => 3, "sportTypeKey" => "hiking" } &&
            body["workoutSegments"][0]["sportType"] == { "sportTypeId" => 3, "sportTypeKey" => "hiking" }
        }
        .to_return(status: 200, body: '{"workoutId": 600, "workoutName": "Trail Hike"}', headers: { "Content-Type" => "application/json" })

      result = client.create_hiking_workout("Trail Hike")

      expect(stub).to have_been_requested.once
      expect(result).to eq("workoutId" => 600, "workoutName" => "Trail Hike")
    end
  end

  describe "#training_plans" do
    it "returns the list of training plans" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/trainingplan-service/trainingplan/plans",
        response_body: [{ "planId" => 1, "planName" => "5K Beginner" }])

      result = client.training_plans

      expect(result).to eq([{ "planId" => 1, "planName" => "5K Beginner" }])
    end
  end

  describe "#training_plan" do
    it "returns the phased training plan for the given ID" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/trainingplan-service/trainingplan/phased/77",
        response_body: { "planId" => 77, "planName" => "Half Marathon", "phases" => [] })

      result = client.training_plan(77)

      expect(result).to eq("planId" => 77, "planName" => "Half Marathon", "phases" => [])
    end
  end

  describe "#adaptive_training_plan" do
    it "returns the adaptive training plan for the given ID" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/trainingplan-service/trainingplan/fbt-adaptive/88",
        response_body: { "planId" => 88, "planName" => "Adaptive 10K", "adaptive" => true })

      result = client.adaptive_training_plan(88)

      expect(result).to eq("planId" => 88, "planName" => "Adaptive 10K", "adaptive" => true)
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
