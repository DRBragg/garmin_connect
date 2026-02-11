# frozen_string_literal: true

module GarminConnect
  module API
    # Workouts and training plan endpoints.
    module Workouts
      # List workouts.
      # @param start [Integer] pagination offset
      # @param limit [Integer]
      def workouts(start: 0, limit: 20)
        connection.get(
          "/workout-service/workouts",
          params: { "start" => start, "limit" => limit }
        )
      end

      # Get a specific workout by ID.
      # @param workout_id [String, Integer]
      def workout(workout_id)
        connection.get("/workout-service/workout/#{workout_id}")
      end

      # Download a workout as a FIT file.
      # @param workout_id [String, Integer]
      # @return [String] raw bytes
      def download_workout(workout_id)
        connection.download("/workout-service/workout/FIT/#{workout_id}")
      end

      # Create/upload a workout from a JSON payload.
      # @param payload [Hash] the workout definition
      def create_workout(payload)
        connection.post("/workout-service/workout", body: payload)
      end

      # Get a scheduled workout by ID.
      # @param scheduled_workout_id [String, Integer]
      def scheduled_workout(scheduled_workout_id)
        connection.get("/workout-service/schedule/#{scheduled_workout_id}")
      end

      # --- Typed Workout Helpers ---

      # Create a running workout.
      # @param name [String] workout name
      # @param steps [Array<Hash>] workout step definitions
      # @param description [String, nil] optional description
      def create_running_workout(name, steps: [], description: nil)
        create_typed_workout(name, sport_type: running_sport_type, steps: steps, description: description)
      end

      # Create a cycling workout.
      # @param name [String] workout name
      # @param steps [Array<Hash>] workout step definitions
      # @param description [String, nil] optional description
      def create_cycling_workout(name, steps: [], description: nil)
        create_typed_workout(name, sport_type: cycling_sport_type, steps: steps, description: description)
      end

      # Create a swimming workout.
      # @param name [String] workout name
      # @param steps [Array<Hash>] workout step definitions
      # @param description [String, nil] optional description
      def create_swimming_workout(name, steps: [], description: nil)
        create_typed_workout(name, sport_type: swimming_sport_type, steps: steps, description: description)
      end

      # Create a walking workout.
      # @param name [String] workout name
      # @param steps [Array<Hash>] workout step definitions
      # @param description [String, nil] optional description
      def create_walking_workout(name, steps: [], description: nil)
        create_typed_workout(name, sport_type: walking_sport_type, steps: steps, description: description)
      end

      # Create a hiking workout.
      # @param name [String] workout name
      # @param steps [Array<Hash>] workout step definitions
      # @param description [String, nil] optional description
      def create_hiking_workout(name, steps: [], description: nil)
        create_typed_workout(name, sport_type: hiking_sport_type, steps: steps, description: description)
      end

      # --- Training Plans ---

      # Get all available training plans.
      def training_plans
        connection.get("/trainingplan-service/trainingplan/plans")
      end

      # Get a phased training plan by ID.
      # @param plan_id [String, Integer]
      def training_plan(plan_id)
        connection.get("/trainingplan-service/trainingplan/phased/#{plan_id}")
      end

      # Get an adaptive training plan by ID.
      # @param plan_id [String, Integer]
      def adaptive_training_plan(plan_id)
        connection.get("/trainingplan-service/trainingplan/fbt-adaptive/#{plan_id}")
      end

      private

      def create_typed_workout(name, sport_type:, steps: [], description: nil)
        payload = {
          "workoutName" => name,
          "sportType" => sport_type,
          "workoutSegments" => [
            {
              "segmentOrder" => 1,
              "sportType" => sport_type,
              "workoutSteps" => steps
            }
          ]
        }
        payload["description"] = description if description

        create_workout(payload)
      end

      def running_sport_type
        { "sportTypeId" => 1, "sportTypeKey" => "running" }
      end

      def cycling_sport_type
        { "sportTypeId" => 2, "sportTypeKey" => "cycling" }
      end

      def swimming_sport_type
        { "sportTypeId" => 5, "sportTypeKey" => "swimming" }
      end

      def walking_sport_type
        { "sportTypeId" => 9, "sportTypeKey" => "walking" }
      end

      def hiking_sport_type
        { "sportTypeId" => 3, "sportTypeKey" => "hiking" }
      end
    end
  end
end
