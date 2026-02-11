# frozen_string_literal: true

module GarminConnect
  module API
    # Body composition, weight, hydration, and blood pressure endpoints.
    module BodyComposition
      # Get body composition data for a date range.
      # @param start_date [Date, String]
      # @param end_date [Date, String]
      def body_composition(start_date = today, end_date = start_date)
        connection.get(
          "/weight-service/weight/dateRange",
          params: {
            "startDate" => format_date(start_date),
            "endDate" => format_date(end_date)
          }
        )
      end

      # Get weigh-ins for a date range.
      # @param start_date [Date, String]
      # @param end_date [Date, String]
      def weigh_ins(start_date, end_date)
        connection.get(
          "/weight-service/weight/range/#{format_date(start_date)}/#{format_date(end_date)}",
          params: { "includeAll" => true }
        )
      end

      # Get weigh-ins for a specific day.
      # @param date [Date, String]
      def daily_weigh_ins(date = today)
        connection.get(
          "/weight-service/weight/dayview/#{format_date(date)}",
          params: { "includeAll" => true }
        )
      end

      # Add a weigh-in.
      # @param value [Float] weight value
      # @param date [Date, String] date of the weigh-in
      # @param unit_key [String] "kg" or "lbs"
      def add_weigh_in(value, date: today, unit_key: "kg")
        timestamp = "#{format_date(date)}T12:00:00.000"
        connection.post(
          "/weight-service/user-weight",
          body: {
            "dateTimestamp" => timestamp,
            "gmtTimestamp" => timestamp,
            "unitKey" => unit_key,
            "sourceType" => "MANUAL",
            "value" => value
          }
        )
      end

      # Delete a specific weigh-in.
      # @param date [Date, String]
      # @param weight_pk [String, Integer] the weigh-in version/pk
      def delete_weigh_in(date, weight_pk)
        connection.delete("/weight-service/weight/#{format_date(date)}/byversion/#{weight_pk}")
      end

      # --- Hydration ---

      # Get daily hydration data.
      # @param date [Date, String]
      def hydration(date = today)
        connection.get("/usersummary-service/usersummary/hydration/daily/#{format_date(date)}")
      end

      # Log hydration intake.
      # @param value_in_ml [Float] amount in milliliters (negative to subtract)
      # @param date [Date, String]
      def log_hydration(value_in_ml, date: today)
        connection.put(
          "/usersummary-service/usersummary/hydration/log",
          body: {
            "calendarDate" => format_date(date),
            "timestampLocal" => "#{format_date(date)}T#{Time.now.strftime("%H:%M:%S")}.000",
            "valueInML" => value_in_ml
          }
        )
      end

      # --- Blood Pressure ---

      # Get blood pressure data for a date range.
      # @param start_date [Date, String]
      # @param end_date [Date, String]
      def blood_pressure(start_date, end_date)
        connection.get(
          "/bloodpressure-service/bloodpressure/range/#{format_date(start_date)}/#{format_date(end_date)}",
          params: { "includeAll" => true }
        )
      end

      # Log a blood pressure measurement.
      # @param systolic [Integer]
      # @param diastolic [Integer]
      # @param pulse [Integer]
      # @param notes [String, nil]
      # @param date [Date, String]
      def log_blood_pressure(systolic:, diastolic:, pulse:, notes: nil, date: today)
        timestamp = "#{format_date(date)}T#{Time.now.strftime("%H:%M:%S")}.000"
        body = {
          "measurementTimestampLocal" => timestamp,
          "measurementTimestampGMT" => timestamp,
          "systolic" => systolic,
          "diastolic" => diastolic,
          "pulse" => pulse,
          "sourceType" => "MANUAL"
        }
        body["notes"] = notes if notes

        connection.post("/bloodpressure-service/bloodpressure", body: body)
      end

      # Delete a blood pressure measurement.
      # @param date [Date, String]
      # @param version [String, Integer]
      def delete_blood_pressure(date, version)
        connection.delete("/bloodpressure-service/bloodpressure/#{format_date(date)}/#{version}")
      end
    end
  end
end
