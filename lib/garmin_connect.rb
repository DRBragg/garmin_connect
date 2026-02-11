# frozen_string_literal: true

require_relative "garmin_connect/version"
require_relative "garmin_connect/errors"
require_relative "garmin_connect/auth/oauth1_token"
require_relative "garmin_connect/auth/oauth2_token"
require_relative "garmin_connect/auth/token_store"
require_relative "garmin_connect/auth/sso"
require_relative "garmin_connect/connection"
require_relative "garmin_connect/api/user"
require_relative "garmin_connect/api/health"
require_relative "garmin_connect/api/activities"
require_relative "garmin_connect/api/body_composition"
require_relative "garmin_connect/api/metrics"
require_relative "garmin_connect/api/devices"
require_relative "garmin_connect/api/badges"
require_relative "garmin_connect/api/workouts"
require_relative "garmin_connect/api/wellness"
require_relative "garmin_connect/client"

module GarminConnect
  class << self
    # Convenience method to create and login a client in one step.
    #
    # @example
    #   client = GarminConnect.login(email: "user@example.com", password: "secret")
    #   client.daily_summary
    #
    # @example Resume from tokens
    #   client = GarminConnect.login(token_dir: "~/.garminconnect")
    def login(**options)
      Client.new(**options).login
    end
  end
end
