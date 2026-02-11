# frozen_string_literal: true

module GarminConnect
  module API
    # Advanced health metrics, scores, and biometric endpoints.
    module Metrics
      # Get VO2 Max data.
      # @param date [Date, String]
      def max_metrics(date = today)
        d = format_date(date)
        connection.get("/metrics-service/metrics/maxmet/daily/#{d}/#{d}")
      end

      # Get training readiness score.
      # @param date [Date, String]
      def training_readiness(date = today)
        connection.get("/metrics-service/metrics/trainingreadiness/#{format_date(date)}")
      end

      # Get morning-only training readiness (filters training_readiness result).
      # @param date [Date, String]
      def morning_training_readiness(date = today)
        data = training_readiness(date)
        return data unless data.is_a?(Array)

        data.select { |entry| entry["calendarDate"] == format_date(date) }
      end

      # Get aggregated training status.
      # @param date [Date, String]
      def training_status(date = today)
        connection.get("/metrics-service/metrics/trainingstatus/aggregated/#{format_date(date)}")
      end

      # Get endurance score.
      # @param date [Date, String] single day, OR
      # @param start_date [Date, String, nil] range start
      # @param end_date [Date, String, nil] range end
      # @param aggregation [String] "weekly" or "daily"
      def endurance_score(date = nil, start_date: nil, end_date: nil, aggregation: "weekly")
        if start_date && end_date
          connection.get(
            "/metrics-service/metrics/endurancescore/stats",
            params: {
              "startDate" => format_date(start_date),
              "endDate" => format_date(end_date),
              "aggregation" => aggregation
            }
          )
        else
          connection.get(
            "/metrics-service/metrics/endurancescore",
            params: { "calendarDate" => format_date(date || today) }
          )
        end
      end

      # Get hill score.
      # @param date [Date, String] single day, OR
      # @param start_date [Date, String, nil] range start
      # @param end_date [Date, String, nil] range end
      # @param aggregation [String] "daily" or "weekly"
      def hill_score(date = nil, start_date: nil, end_date: nil, aggregation: "daily")
        if start_date && end_date
          connection.get(
            "/metrics-service/metrics/hillscore/stats",
            params: {
              "startDate" => format_date(start_date),
              "endDate" => format_date(end_date),
              "aggregation" => aggregation
            }
          )
        else
          connection.get(
            "/metrics-service/metrics/hillscore",
            params: { "calendarDate" => format_date(date || today) }
          )
        end
      end

      # Get race predictions (5k, 10k, half, full marathon).
      # @param type [String, nil] nil for latest, or "daily"/"monthly" for range
      # @param start_date [Date, String, nil]
      # @param end_date [Date, String, nil]
      def race_predictions(type: nil, start_date: nil, end_date: nil)
        if type && start_date && end_date
          connection.get(
            "/metrics-service/metrics/racepredictions/#{type}/#{display_name}",
            params: {
              "fromCalendarDate" => format_date(start_date),
              "toCalendarDate" => format_date(end_date)
            }
          )
        else
          connection.get("/metrics-service/metrics/racepredictions/latest/#{display_name}")
        end
      end

      # Get fitness age.
      # @param date [Date, String]
      def fitness_age(date = today)
        connection.get("/fitnessage-service/fitnessage/#{format_date(date)}")
      end

      # --- Biometrics ---

      # Get latest lactate threshold data.
      def lactate_threshold
        connection.get("/biometric-service/biometric/latestLactateThreshold")
      end

      # Get lactate threshold history over a date range.
      # @param start_date [Date, String]
      # @param end_date [Date, String]
      # @param aggregation [String] "daily", "weekly", "monthly", or "yearly"
      def lactate_threshold_history(start_date, end_date, aggregation: "daily")
        params = {
          "sport" => "RUNNING",
          "aggregation" => aggregation,
          "aggregationStrategy" => "LATEST"
        }

        {
          "speed" => connection.get(
            "/biometric-service/stats/lactateThresholdSpeed/range/#{format_date(start_date)}/#{format_date(end_date)}",
            params: params
          ),
          "heart_rate" => connection.get(
            "/biometric-service/stats/lactateThresholdHeartRate/range/#{format_date(start_date)}/#{format_date(end_date)}",
            params: params
          ),
          "power" => connection.get(
            "/biometric-service/stats/functionalThresholdPower/range/#{format_date(start_date)}/#{format_date(end_date)}",
            params: params
          )
        }
      end

      # Get latest cycling FTP (Functional Threshold Power).
      def cycling_ftp
        connection.get("/biometric-service/biometric/latestFunctionalThresholdPower/CYCLING")
      end

      # --- Historical / Trends ---

      # Get daily steps over a date range (auto-chunks at 28 days).
      # @param start_date [Date, String]
      # @param end_date [Date, String]
      def daily_steps(start_date, end_date)
        chunked_request(start_date, end_date, 28) do |chunk_start, chunk_end|
          connection.get("/usersummary-service/stats/steps/daily/#{format_date(chunk_start)}/#{format_date(chunk_end)}")
        end
      end

      # Get weekly steps.
      # @param end_date [Date, String]
      # @param weeks [Integer]
      def weekly_steps(end_date = today, weeks: 52)
        connection.get("/usersummary-service/stats/steps/weekly/#{format_date(end_date)}/#{weeks}")
      end

      # Get weekly stress.
      # @param end_date [Date, String]
      # @param weeks [Integer]
      def weekly_stress(end_date = today, weeks: 52)
        connection.get("/usersummary-service/stats/stress/weekly/#{format_date(end_date)}/#{weeks}")
      end

      # Get weekly intensity minutes.
      # @param start_date [Date, String]
      # @param end_date [Date, String]
      def weekly_intensity_minutes(start_date, end_date = today)
        connection.get("/usersummary-service/stats/im/weekly/#{format_date(start_date)}/#{format_date(end_date)}")
      end
    end
  end
end
