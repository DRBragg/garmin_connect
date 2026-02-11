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
    end
  end
end
