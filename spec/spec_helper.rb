# frozen_string_literal: true

require "garmin_connect"
require "webmock/rspec"
require "vcr"
require "json"

VCR.configure do |config|
  config.cassette_library_dir = "spec/cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.default_cassette_options = { record: :none }

  # Filter sensitive data from cassettes
  config.filter_sensitive_data("<OAUTH1_TOKEN>") { |interaction| extract_oauth1_token(interaction) }
  config.filter_sensitive_data("<ACCESS_TOKEN>") { |interaction| extract_access_token(interaction) }
  config.filter_sensitive_data("<CONSUMER_KEY>") { "fc3e99d2-118c-44b8-8ae3-03370dde24c0" }
end

def extract_oauth1_token(interaction)
  interaction.response.body[/oauth_token=([^&]+)/, 1] if interaction.response.body.include?("oauth_token=")
end

def extract_access_token(interaction)
  auth = interaction.request.headers["Authorization"]&.first
  auth&.sub(/^Bearer /, "")
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.order = :random
  Kernel.srand config.seed
end

# --- Test helpers ---

def build_oauth1_token(overrides = {})
  GarminConnect::Auth::OAuth1Token.new(
    token: "test-oauth1-token",
    secret: "test-oauth1-secret",
    domain: "garmin.com",
    **overrides
  )
end

def build_oauth2_token(overrides = {})
  GarminConnect::Auth::OAuth2Token.new(
    access_token: "test-access-token",
    refresh_token: "test-refresh-token",
    token_type: "Bearer",
    expires_in: 3600,
    expires_at: Time.now.to_i + 3600,
    **overrides
  )
end

def build_connection(oauth1: nil, oauth2: nil)
  GarminConnect::Connection.new(
    oauth1_token: oauth1 || build_oauth1_token,
    oauth2_token: oauth2 || build_oauth2_token
  )
end

def stub_garmin_api(method, path, response_body: {}, status: 200)
  stub_request(method, "https://connectapi.garmin.com#{path}")
    .to_return(
      status: status,
      body: response_body.to_json,
      headers: { "Content-Type" => "application/json" }
    )
end
