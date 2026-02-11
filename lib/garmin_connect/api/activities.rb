# frozen_string_literal: true

module GarminConnect
  module API
    # Activity listing, details, CRUD, and download/upload endpoints.
    module Activities
      DOWNLOAD_FORMATS = {
        original: "/download-service/files/activity/%s",
        tcx: "/download-service/export/tcx/activity/%s",
        gpx: "/download-service/export/gpx/activity/%s",
        kml: "/download-service/export/kml/activity/%s",
        csv: "/download-service/export/csv/activity/%s"
      }.freeze

      # List activities with optional filters.
      # @param start [Integer] pagination offset
      # @param limit [Integer] max results
      # @param activity_type [String, nil] filter by activity type
      # @param sort_order [String] "asc" or "desc"
      def activities(start: 0, limit: 20, activity_type: nil, sort_order: "desc")
        params = { "start" => start, "limit" => limit }
        params["activityType"] = activity_type if activity_type
        params["sortOrder"] = sort_order

        connection.get("/activitylist-service/activities/search/activities", params: params)
      end

      # Get activities within a date range.
      # @param start_date [Date, String]
      # @param end_date [Date, String]
      # @param activity_type [String, nil]
      def activities_by_date(start_date, end_date, activity_type: nil)
        params = {
          "startDate" => format_date(start_date),
          "endDate" => format_date(end_date),
          "start" => 0,
          "limit" => 100
        }
        params["activityType"] = activity_type if activity_type

        connection.get("/activitylist-service/activities/search/activities", params: params)
      end

      # Get the total activity count.
      def activity_count
        connection.get("/activitylist-service/activities/count")
      end

      # Get the most recent activity.
      def last_activity
        results = activities(start: 0, limit: 1)
        results&.first
      end

      # Get a single activity's summary.
      # @param activity_id [String, Integer]
      def activity(activity_id)
        connection.get("/activity-service/activity/#{activity_id}")
      end

      # Get detailed activity data (charts, polylines).
      # @param activity_id [String, Integer]
      # @param max_chart_size [Integer]
      # @param max_polyline_size [Integer]
      def activity_details(activity_id, max_chart_size: 2000, max_polyline_size: 4000)
        connection.get(
          "/activity-service/activity/#{activity_id}/details",
          params: { "maxChartSize" => max_chart_size, "maxPolylineSize" => max_polyline_size }
        )
      end

      # Get activity splits.
      def activity_splits(activity_id)
        connection.get("/activity-service/activity/#{activity_id}/splits")
      end

      # Get typed activity splits.
      def activity_typed_splits(activity_id)
        connection.get("/activity-service/activity/#{activity_id}/typedsplits")
      end

      # Get activity split summaries.
      def activity_split_summaries(activity_id)
        connection.get("/activity-service/activity/#{activity_id}/split_summaries")
      end

      # Get weather data for an activity.
      def activity_weather(activity_id)
        connection.get("/activity-service/activity/#{activity_id}/weather")
      end

      # Get heart rate time-in-zones for an activity.
      def activity_hr_zones(activity_id)
        connection.get("/activity-service/activity/#{activity_id}/hrTimeInZones")
      end

      # Get power time-in-zones for an activity.
      def activity_power_zones(activity_id)
        connection.get("/activity-service/activity/#{activity_id}/powerTimeInZones")
      end

      # Get exercise sets for an activity.
      def activity_exercise_sets(activity_id)
        connection.get("/activity-service/activity/#{activity_id}/exerciseSets")
      end

      # Get all available activity types.
      def activity_types
        connection.get("/activity-service/activity/activityTypes")
      end

      # Get heart rate activities for a specific date.
      def heart_rate_activities(date = today)
        connection.get("/mobile-gateway/heartRate/forDate/#{format_date(date)}")
      end

      # --- CRUD ---

      # Create a manual activity from a hash/JSON payload.
      # @param payload [Hash] the activity data
      def create_activity(payload)
        connection.post("/activity-service/activity", body: payload)
      end

      # Rename an activity.
      # @param activity_id [String, Integer]
      # @param name [String]
      def rename_activity(activity_id, name)
        connection.put(
          "/activity-service/activity/#{activity_id}",
          body: { "activityId" => activity_id, "activityName" => name }
        )
      end

      # Change an activity's type.
      # @param activity_id [String, Integer]
      # @param activity_type [Hash] the activityTypeDTO
      def update_activity_type(activity_id, activity_type)
        connection.put(
          "/activity-service/activity/#{activity_id}",
          body: { "activityId" => activity_id, "activityTypeDTO" => activity_type }
        )
      end

      # Delete an activity.
      def delete_activity(activity_id)
        connection.delete("/activity-service/activity/#{activity_id}")
      end

      # --- Download / Upload ---

      # Download an activity file.
      # @param activity_id [String, Integer]
      # @param format [Symbol] :original, :tcx, :gpx, :kml, or :csv
      # @return [String] raw file bytes
      def download_activity(activity_id, format: :original)
        path = DOWNLOAD_FORMATS.fetch(format) do
          raise ArgumentError, "Unknown format: #{format}. Use: #{DOWNLOAD_FORMATS.keys.join(", ")}"
        end

        connection.download(path % activity_id)
      end

      # Upload an activity file (FIT, GPX, or TCX).
      # @param file_path [String] path to the file
      def upload_activity(file_path)
        connection.upload("/upload-service/upload", file_path: file_path)
      end

      # --- Progress ---

      # Get progress summary between dates.
      # @param start_date [Date, String]
      # @param end_date [Date, String]
      # @param metric [String] e.g., "distance", "duration", "elevationGain"
      def progress_summary(start_date, end_date, metric: "distance")
        connection.get(
          "/fitnessstats-service/activity",
          params: {
            "startDate" => format_date(start_date),
            "endDate" => format_date(end_date),
            "aggregation" => "lifetime",
            "groupByParentActivityType" => true,
            "metric" => metric
          }
        )
      end
    end
  end
end
