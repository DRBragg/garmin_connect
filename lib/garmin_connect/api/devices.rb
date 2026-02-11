# frozen_string_literal: true

module GarminConnect
  module API
    # Device and gear management endpoints.
    module Devices
      # List all registered devices.
      def devices
        connection.get("/device-service/deviceregistration/devices")
      end

      # Get settings for a specific device (includes alarms).
      # @param device_id [String, Integer]
      def device_settings(device_id)
        connection.get("/device-service/deviceservice/device-info/settings/#{device_id}")
      end

      # Get the last used device.
      def last_used_device
        connection.get("/device-service/deviceservice/mylastused")
      end

      # Get primary training device info.
      def primary_training_device
        connection.get("/web-gateway/device-info/primary-training-device")
      end

      # Get solar charging data for a device.
      # @param device_id [String, Integer]
      # @param start_date [Date, String]
      # @param end_date [Date, String]
      # @param single_day [Boolean]
      def device_solar_data(device_id, start_date, end_date, single_day: false)
        connection.get(
          "/web-gateway/solar/#{device_id}/#{format_date(start_date)}/#{format_date(end_date)}",
          params: { "singleDayView" => single_day }
        )
      end

      # Get alarms for all devices.
      def device_alarms
        all_devices = devices
        return [] unless all_devices.is_a?(Array)

        all_devices.filter_map do |device|
          device_id = device["deviceId"]
          next unless device_id

          settings = device_settings(device_id)
          alarms = settings&.dig("alarms")
          { "device" => device, "alarms" => alarms } if alarms
        end
      end

      # --- Gear ---

      # Get all gear for the current user.
      def gear
        connection.get(
          "/gear-service/gear/filterGear",
          params: { "userProfilePk" => user_profile_pk }
        )
      end

      # Get gear linked to an activity.
      # @param activity_id [String, Integer]
      def activity_gear(activity_id)
        connection.get(
          "/gear-service/gear/filterGear",
          params: { "activityId" => activity_id }
        )
      end

      # Get statistics for a gear item.
      # @param gear_uuid [String]
      def gear_stats(gear_uuid)
        connection.get("/gear-service/gear/stats/#{gear_uuid}")
      end

      # Get default gear assignments per activity type.
      def gear_defaults
        connection.get("/gear-service/gear/user/#{user_profile_pk}/activityTypes")
      end

      # Set or remove a gear item as default for an activity type.
      # @param gear_uuid [String]
      # @param activity_type [String]
      # @param default [Boolean]
      def set_gear_default(gear_uuid, activity_type, default: true)
        if default
          connection.put("/gear-service/gear/#{gear_uuid}/activityType/#{activity_type}/default/true")
        else
          connection.delete("/gear-service/gear/#{gear_uuid}/activityType/#{activity_type}")
        end
      end

      # Link gear to an activity.
      def link_gear(gear_uuid, activity_id)
        connection.put("/gear-service/gear/link/#{gear_uuid}/activity/#{activity_id}")
      end

      # Unlink gear from an activity.
      def unlink_gear(gear_uuid, activity_id)
        connection.put("/gear-service/gear/unlink/#{gear_uuid}/activity/#{activity_id}")
      end

      # Get activities associated with a gear item.
      # @param gear_uuid [String]
      # @param limit [Integer]
      def gear_activities(gear_uuid, limit: 20)
        connection.get(
          "/activitylist-service/activities/#{gear_uuid}/gear",
          params: { "start" => 0, "limit" => limit }
        )
      end
    end
  end
end
