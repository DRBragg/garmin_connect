# frozen_string_literal: true

module GarminConnect
  module API
    # User profile and settings endpoints.
    module User
      # Get the current user's profile settings (measurement system, sleep, etc.).
      def user_settings
        connection.get("/userprofile-service/userprofile/user-settings")
      end

      # Get the current user's profile configuration.
      def user_profile
        connection.get("/userprofile-service/userprofile/settings")
      end

      # Get personal information for a display name.
      # @param display_name [String] defaults to the logged-in user
      def personal_information(display_name = self.display_name)
        connection.get("/userprofile-service/userprofile/personal-information/#{display_name}")
      end

      # Get the full name of the logged-in user.
      def full_name
        @full_name
      end

      # Get the display name of the logged-in user.
      def display_name
        @display_name
      end

      # Get the measurement system (statute_us, metric, etc.).
      def unit_system
        @unit_system
      end
    end
  end
end
