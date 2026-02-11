# frozen_string_literal: true

module GarminConnect
  module API
    # Badges, challenges, personal records, and goals endpoints.
    module Badges
      # Get all earned badges.
      def earned_badges
        connection.get("/badge-service/badge/earned")
      end

      # Get all available badges.
      def available_badges
        connection.get(
          "/badge-service/badge/available",
          params: { "showExclusiveBadge" => true }
        )
      end

      # Get badges currently in progress.
      def in_progress_badges
        earned = earned_badges
        available = available_badges
        return [] unless earned.is_a?(Array) && available.is_a?(Array)

        earned_ids = earned.map { |b| b["badgeId"] }.compact.to_set
        available.reject { |b| earned_ids.include?(b["badgeId"]) }
      end

      # Get historical ad-hoc challenges.
      # @param start [Integer] pagination offset
      # @param limit [Integer]
      def adhoc_challenges(start: 0, limit: 20)
        connection.get(
          "/adhocchallenge-service/adHocChallenge/historical",
          params: { "start" => start, "limit" => limit }
        )
      end

      # Get completed badge challenges.
      def badge_challenges(start: 0, limit: 20)
        connection.get(
          "/badgechallenge-service/badgeChallenge/completed",
          params: { "start" => start, "limit" => limit }
        )
      end

      # Get available badge challenges.
      def available_badge_challenges(start: 0, limit: 20)
        connection.get(
          "/badgechallenge-service/badgeChallenge/available",
          params: { "start" => start, "limit" => limit }
        )
      end

      # Get non-completed badge challenges.
      def non_completed_badge_challenges(start: 0, limit: 20)
        connection.get(
          "/badgechallenge-service/badgeChallenge/non-completed",
          params: { "start" => start, "limit" => limit }
        )
      end

      # Get in-progress virtual challenges.
      def virtual_challenges(start: 0, limit: 20)
        connection.get(
          "/badgechallenge-service/virtualChallenge/inProgress",
          params: { "start" => start, "limit" => limit }
        )
      end

      # --- Personal Records ---

      # Get personal records.
      # @param display_name [String] defaults to the logged-in user
      def personal_records(display_name = self.display_name)
        connection.get("/personalrecord-service/personalrecord/prs/#{display_name}")
      end

      # --- Goals ---

      # Get goals by status.
      # @param status [String] "active", "future", or "past"
      # @param start [Integer] pagination offset
      # @param limit [Integer]
      def goals(status: "active", start: 0, limit: 20)
        connection.get(
          "/goal-service/goal/goals",
          params: { "status" => status, "start" => start, "limit" => limit, "sortOrder" => "asc" }
        )
      end
    end
  end
end
