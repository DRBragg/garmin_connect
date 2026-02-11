# frozen_string_literal: true

module GarminConnect
  module API
    # Menstrual cycle, pregnancy, lifestyle logging, and GraphQL endpoints.
    module Wellness
      # Get menstrual cycle data for a specific date.
      # @param date [Date, String]
      def menstrual_data(date = today)
        connection.get("/periodichealth-service/menstrualcycle/dayview/#{format_date(date)}")
      end

      # Get menstrual cycle calendar for a date range.
      # @param start_date [Date, String]
      # @param end_date [Date, String]
      def menstrual_calendar(start_date, end_date)
        connection.get(
          "/periodichealth-service/menstrualcycle/calendar/#{format_date(start_date)}/#{format_date(end_date)}"
        )
      end

      # Get pregnancy summary snapshot.
      def pregnancy_summary
        connection.get("/periodichealth-service/menstrualcycle/pregnancysnapshot")
      end

      # Get daily lifestyle logging data.
      # @param date [Date, String]
      def lifestyle_logging(date = today)
        connection.get("/lifestylelogging-service/dailyLog/#{format_date(date)}")
      end

      # Execute a GraphQL query against Garmin's gateway.
      # @param query [String] the GraphQL query string
      # @param variables [Hash] query variables
      # @param operation_name [String, nil]
      def graphql(query, variables: {}, operation_name: nil)
        body = { "query" => query, "variables" => variables }
        body["operationName"] = operation_name if operation_name

        connection.post("/graphql-gateway/graphql", body: body)
      end
    end
  end
end
