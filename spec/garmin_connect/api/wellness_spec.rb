# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe GarminConnect::API::Wellness do
  describe "#menstrual_data" do
    it "fetches menstrual cycle day view for a given date" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/periodichealth-service/menstrualcycle/dayview/2026-02-11",
        response_body: { "cycleDay" => 14, "phase" => "LUTEAL" })

      result = client.menstrual_data("2026-02-11")

      expect(result).to eq("cycleDay" => 14, "phase" => "LUTEAL")
    end
  end

  describe "#menstrual_calendar" do
    it "fetches menstrual cycle calendar for a date range" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/periodichealth-service/menstrualcycle/calendar/2026-01-01/2026-02-11",
        response_body: { "cycles" => [{ "startDate" => "2026-01-15" }] })

      result = client.menstrual_calendar("2026-01-01", "2026-02-11")

      expect(result).to eq("cycles" => [{ "startDate" => "2026-01-15" }])
    end
  end

  describe "#pregnancy_summary" do
    it "fetches the pregnancy snapshot" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/periodichealth-service/menstrualcycle/pregnancysnapshot",
        response_body: { "pregnancyStatus" => "NOT_PREGNANT" })

      result = client.pregnancy_summary

      expect(result).to eq("pregnancyStatus" => "NOT_PREGNANT")
    end
  end

  describe "#lifestyle_logging" do
    it "fetches daily lifestyle logging data for a given date" do
      client = build_logged_in_client

      stub_garmin_api(:get, "/lifestylelogging-service/dailyLog/2026-02-11",
        response_body: { "calories" => 2100, "water" => 1500 })

      result = client.lifestyle_logging("2026-02-11")

      expect(result).to eq("calories" => 2100, "water" => 1500)
    end
  end

  describe "#graphql" do
    it "posts a basic GraphQL query" do
      client = build_logged_in_client

      stub = stub_request(:post, "https://connectapi.garmin.com/graphql-gateway/graphql")
        .with(body: { "query" => "{ currentUser { displayName } }", "variables" => {} })
        .to_return(status: 200, body: '{"data": {"currentUser": {"displayName": "TestUser"}}}', headers: { "Content-Type" => "application/json" })

      result = client.graphql("{ currentUser { displayName } }")

      expect(result).to eq("data" => { "currentUser" => { "displayName" => "TestUser" } })
      expect(stub).to have_been_requested.once
    end

    it "posts a GraphQL query with variables" do
      client = build_logged_in_client

      stub = stub_request(:post, "https://connectapi.garmin.com/graphql-gateway/graphql")
        .with(body: { "query" => "query($id: ID!) { activity(id: $id) { name } }", "variables" => { "id" => "12345" } })
        .to_return(status: 200, body: '{"data": {"activity": {"name": "Morning Run"}}}', headers: { "Content-Type" => "application/json" })

      result = client.graphql("query($id: ID!) { activity(id: $id) { name } }", variables: { "id" => "12345" })

      expect(result).to eq("data" => { "activity" => { "name" => "Morning Run" } })
      expect(stub).to have_been_requested.once
    end

    it "includes operationName when provided" do
      client = build_logged_in_client

      stub = stub_request(:post, "https://connectapi.garmin.com/graphql-gateway/graphql")
        .with(body: { "query" => "query GetUser { currentUser { displayName } }", "variables" => {}, "operationName" => "GetUser" })
        .to_return(status: 200, body: '{"data": {"currentUser": {"displayName": "TestUser"}}}', headers: { "Content-Type" => "application/json" })

      result = client.graphql("query GetUser { currentUser { displayName } }", operation_name: "GetUser")

      expect(result).to eq("data" => { "currentUser" => { "displayName" => "TestUser" } })
      expect(stub).to have_been_requested.once
    end

    it "does not include operationName key when operation_name is nil" do
      client = build_logged_in_client

      stub = stub_request(:post, "https://connectapi.garmin.com/graphql-gateway/graphql")
        .with { |request| JSON.parse(request.body).keys == %w[query variables] }
        .to_return(status: 200, body: '{"data": {}}', headers: { "Content-Type" => "application/json" })

      client.graphql("{ currentUser { displayName } }")

      expect(stub).to have_been_requested.once
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
