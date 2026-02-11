# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe GarminConnect::API::Badges do
  describe "#earned_badges" do
    it "returns earned badges" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/badge-service/badge/earned")
        .to_return(status: 200, body: '[{"badgeId": 1, "badgeName": "First Step"}, {"badgeId": 2, "badgeName": "Marathon"}]', headers: { "Content-Type" => "application/json" })

      result = client.earned_badges

      expect(result).to eq([{ "badgeId" => 1, "badgeName" => "First Step" }, { "badgeId" => 2, "badgeName" => "Marathon" }])
    end
  end

  describe "#available_badges" do
    it "returns available badges with showExclusiveBadge param" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/badge-service/badge/available")
        .with(query: { "showExclusiveBadge" => "true" })
        .to_return(status: 200, body: '[{"badgeId": 3, "badgeName": "Explorer"}]', headers: { "Content-Type" => "application/json" })

      result = client.available_badges

      expect(result).to eq([{ "badgeId" => 3, "badgeName" => "Explorer" }])
    end
  end

  describe "#in_progress_badges" do
    it "returns badges that are available but not yet earned" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/badge-service/badge/earned")
        .to_return(status: 200, body: '[{"badgeId": 1, "badgeName": "First Step"}, {"badgeId": 2, "badgeName": "Marathon"}]', headers: { "Content-Type" => "application/json" })

      stub_request(:get, "https://connectapi.garmin.com/badge-service/badge/available")
        .with(query: { "showExclusiveBadge" => "true" })
        .to_return(status: 200, body: '[{"badgeId": 1, "badgeName": "First Step"}, {"badgeId": 2, "badgeName": "Marathon"}, {"badgeId": 3, "badgeName": "Explorer"}, {"badgeId": 4, "badgeName": "Climber"}]', headers: { "Content-Type" => "application/json" })

      result = client.in_progress_badges

      expect(result).to eq([{ "badgeId" => 3, "badgeName" => "Explorer" }, { "badgeId" => 4, "badgeName" => "Climber" }])
    end

    it "returns an empty array when earned_badges is not an array" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/badge-service/badge/earned")
        .to_return(status: 200, body: '{"error": "something went wrong"}', headers: { "Content-Type" => "application/json" })

      stub_request(:get, "https://connectapi.garmin.com/badge-service/badge/available")
        .with(query: { "showExclusiveBadge" => "true" })
        .to_return(status: 200, body: '[{"badgeId": 1}]', headers: { "Content-Type" => "application/json" })

      result = client.in_progress_badges

      expect(result).to eq([])
    end

    it "returns an empty array when available_badges is not an array" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/badge-service/badge/earned")
        .to_return(status: 200, body: '[{"badgeId": 1}]', headers: { "Content-Type" => "application/json" })

      stub_request(:get, "https://connectapi.garmin.com/badge-service/badge/available")
        .with(query: { "showExclusiveBadge" => "true" })
        .to_return(status: 200, body: '{"error": "something went wrong"}', headers: { "Content-Type" => "application/json" })

      result = client.in_progress_badges

      expect(result).to eq([])
    end
  end

  describe "#adhoc_challenges" do
    it "returns adhoc challenges with default parameters" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/adhocchallenge-service/adHocChallenge/historical")
        .with(query: { "start" => "0", "limit" => "20" })
        .to_return(status: 200, body: '[{"challengeId": 1}]', headers: { "Content-Type" => "application/json" })

      result = client.adhoc_challenges

      expect(result).to eq([{ "challengeId" => 1 }])
    end

    it "passes custom start and limit parameters" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/adhocchallenge-service/adHocChallenge/historical")
        .with(query: { "start" => "10", "limit" => "50" })
        .to_return(status: 200, body: '[{"challengeId": 5}]', headers: { "Content-Type" => "application/json" })

      result = client.adhoc_challenges(start: 10, limit: 50)

      expect(result).to eq([{ "challengeId" => 5 }])
    end
  end

  describe "#badge_challenges" do
    it "returns completed badge challenges with default parameters" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/badgechallenge-service/badgeChallenge/completed")
        .with(query: { "start" => "0", "limit" => "20" })
        .to_return(status: 200, body: '[{"challengeId": 10, "challengeName": "5K Challenge"}]', headers: { "Content-Type" => "application/json" })

      result = client.badge_challenges

      expect(result).to eq([{ "challengeId" => 10, "challengeName" => "5K Challenge" }])
    end
  end

  describe "#available_badge_challenges" do
    it "returns available badge challenges with default parameters" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/badgechallenge-service/badgeChallenge/available")
        .with(query: { "start" => "0", "limit" => "20" })
        .to_return(status: 200, body: '[{"challengeId": 20, "challengeName": "10K Challenge"}]', headers: { "Content-Type" => "application/json" })

      result = client.available_badge_challenges

      expect(result).to eq([{ "challengeId" => 20, "challengeName" => "10K Challenge" }])
    end
  end

  describe "#non_completed_badge_challenges" do
    it "returns non-completed badge challenges with default parameters" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/badgechallenge-service/badgeChallenge/non-completed")
        .with(query: { "start" => "0", "limit" => "20" })
        .to_return(status: 200, body: '[{"challengeId": 30, "challengeName": "Half Marathon"}]', headers: { "Content-Type" => "application/json" })

      result = client.non_completed_badge_challenges

      expect(result).to eq([{ "challengeId" => 30, "challengeName" => "Half Marathon" }])
    end
  end

  describe "#virtual_challenges" do
    it "returns in-progress virtual challenges with default parameters" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/badgechallenge-service/virtualChallenge/inProgress")
        .with(query: { "start" => "0", "limit" => "20" })
        .to_return(status: 200, body: '[{"challengeId": 40, "challengeName": "Virtual 5K"}]', headers: { "Content-Type" => "application/json" })

      result = client.virtual_challenges

      expect(result).to eq([{ "challengeId" => 40, "challengeName" => "Virtual 5K" }])
    end
  end

  describe "#personal_records" do
    it "returns personal records using the default display name" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/personalrecord-service/personalrecord/prs/TestUser")
        .to_return(status: 200, body: '[{"typeId": 1, "value": 1200.0}]', headers: { "Content-Type" => "application/json" })

      result = client.personal_records

      expect(result).to eq([{ "typeId" => 1, "value" => 1200.0 }])
    end

    it "returns personal records for an explicit display name" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/personalrecord-service/personalrecord/prs/OtherUser")
        .to_return(status: 200, body: '[{"typeId": 2, "value" : 500.0}]', headers: { "Content-Type" => "application/json" })

      result = client.personal_records("OtherUser")

      expect(result).to eq([{ "typeId" => 2, "value" => 500.0 }])
    end
  end

  describe "#goals" do
    it "returns active goals with default parameters" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/goal-service/goal/goals")
        .with(query: { "status" => "active", "start" => "0", "limit" => "20", "sortOrder" => "asc" })
        .to_return(status: 200, body: '[{"goalId": 1, "goalType": "steps"}]', headers: { "Content-Type" => "application/json" })

      result = client.goals

      expect(result).to eq([{ "goalId" => 1, "goalType" => "steps" }])
    end

    it "returns goals with a custom status" do
      client = build_logged_in_client

      stub_request(:get, "https://connectapi.garmin.com/goal-service/goal/goals")
        .with(query: { "status" => "past", "start" => "0", "limit" => "20", "sortOrder" => "asc" })
        .to_return(status: 200, body: '[{"goalId": 2, "goalType": "distance", "status": "past"}]', headers: { "Content-Type" => "application/json" })

      result = client.goals(status: "past")

      expect(result).to eq([{ "goalId" => 2, "goalType" => "distance", "status" => "past" }])
    end
  end

  private

  def build_logged_in_client
    dir = Dir.mktmpdir
    GarminConnect::Auth::TokenStore.save(dir, oauth1_token: build_oauth1_token, oauth2_token: build_oauth2_token)
    stub_request(:get, "https://connectapi.garmin.com/userprofile-service/userprofile/user-settings")
      .to_return(status: 200, body: '{"id": 123, "userData": {"measurementSystem": "metric"}}', headers: { "Content-Type" => "application/json" })
    stub_request(:get, "https://connectapi.garmin.com/userprofile-service/userprofile/profile")
      .to_return(status: 200, body: '{"displayName": "TestUser", "fullName": "Test User", "profileId": 123}', headers: { "Content-Type" => "application/json" })
    client = GarminConnect::Client.new(token_dir: dir)
    client.login
    client
  end
end
