# frozen_string_literal: true

module GarminConnect
  module API
    # Daily health and wellness data endpoints.
    module Health
      # Get daily activity summary (steps, calories, distance, etc.).
      # @param date [Date, String] the date (YYYY-MM-DD)
      def daily_summary(date = today)
        connection.get(
          "/usersummary-service/usersummary/daily/#{display_name}",
          params: { "calendarDate" => format_date(date) }
        )
      end

      alias_method :stats, :daily_summary

      # Get combined daily stats and body composition.
      # @param date [Date, String]
      def stats_and_body(date = today)
        {
          "stats" => daily_summary(date),
          "body_composition" => body_composition(date, date)
        }
      end

      # Get heart rate data for a day.
      # @param date [Date, String]
      def heart_rates(date = today)
        connection.get(
          "/wellness-service/wellness/dailyHeartRate/#{display_name}",
          params: { "date" => format_date(date) }
        )
      end

      # Get resting heart rate for a date range.
      # @param start_date [Date, String]
      # @param end_date [Date, String]
      def resting_heart_rate(start_date, end_date = start_date)
        connection.get(
          "/userstats-service/wellness/daily/#{display_name}",
          params: {
            "fromDate" => format_date(start_date),
            "untilDate" => format_date(end_date),
            "metricId" => 60
          }
        )
      end

      # Get Heart Rate Variability data.
      # @param date [Date, String]
      def hrv(date = today)
        connection.get("/hrv-service/hrv/#{format_date(date)}")
      end

      # Get sleep data for a day.
      # @param date [Date, String]
      def sleep_data(date = today)
        connection.get(
          "/wellness-service/wellness/dailySleepData/#{display_name}",
          params: { "date" => format_date(date), "nonSleepBufferMinutes" => 60 }
        )
      end

      # Get all-day stress data.
      # @param date [Date, String]
      def stress(date = today)
        connection.get("/wellness-service/wellness/dailyStress/#{format_date(date)}")
      end

      # Get body battery daily report.
      # @param start_date [Date, String]
      # @param end_date [Date, String]
      def body_battery(start_date = today, end_date = start_date)
        connection.get(
          "/wellness-service/wellness/bodyBattery/reports/daily",
          params: {
            "startDate" => format_date(start_date),
            "endDate" => format_date(end_date)
          }
        )
      end

      # Get body battery events (sleep, activities, naps).
      # @param date [Date, String]
      def body_battery_events(date = today)
        connection.get("/wellness-service/wellness/bodyBattery/events/#{format_date(date)}")
      end

      # Get steps chart data for a day.
      # @param date [Date, String]
      def steps_data(date = today)
        connection.get(
          "/wellness-service/wellness/dailySummaryChart/#{display_name}",
          params: { "date" => format_date(date) }
        )
      end

      # Get floors climbed data for a day.
      # @param date [Date, String]
      def floors(date = today)
        connection.get("/wellness-service/wellness/floorsChartData/daily/#{format_date(date)}")
      end

      # Get daily respiration data.
      # @param date [Date, String]
      def respiration(date = today)
        connection.get("/wellness-service/wellness/daily/respiration/#{format_date(date)}")
      end

      # Get daily SpO2 (blood oxygen) data.
      # @param date [Date, String]
      def spo2(date = today)
        connection.get("/wellness-service/wellness/daily/spo2/#{format_date(date)}")
      end

      # Get daily intensity minutes.
      # @param date [Date, String]
      def intensity_minutes(date = today)
        connection.get("/wellness-service/wellness/daily/im/#{format_date(date)}")
      end

      # Get all-day events (auto-detected activities, etc.).
      # @param date [Date, String]
      def daily_events(date = today)
        connection.get(
          "/wellness-service/wellness/dailyEvents",
          params: { "calendarDate" => format_date(date) }
        )
      end

      # Request reload of offloaded data for a date.
      # @param date [Date, String]
      def request_reload(date = today)
        connection.post("/wellness-service/wellness/epoch/request/#{format_date(date)}")
      end
    end
  end
end
