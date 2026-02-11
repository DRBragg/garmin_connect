# frozen_string_literal: true

require "spec_helper"

RSpec.describe GarminConnect::Auth::OAuth1Token do
  describe "#initialize" do
    it "stores token attributes" do
      token = described_class.new(
        token: "abc123",
        secret: "secret456",
        mfa_token: "mfa789",
        mfa_expiration: "2026-12-31",
        domain: "garmin.com"
      )

      expect(token.token).to eq("abc123")
      expect(token.secret).to eq("secret456")
      expect(token.mfa_token).to eq("mfa789")
      expect(token.mfa_expiration).to eq("2026-12-31")
      expect(token.domain).to eq("garmin.com")
    end

    it "defaults domain to garmin.com" do
      token = described_class.new(token: "t", secret: "s")
      expect(token.domain).to eq("garmin.com")
    end

    it "defaults mfa fields to nil" do
      token = described_class.new(token: "t", secret: "s")
      expect(token.mfa_token).to be_nil
      expect(token.mfa_expiration).to be_nil
    end
  end

  describe "#to_h" do
    it "returns a hash compatible with garth format" do
      token = described_class.new(token: "abc", secret: "def", domain: "garmin.com")
      hash = token.to_h

      expect(hash).to eq(
        "oauth_token" => "abc",
        "oauth_token_secret" => "def",
        "mfa_token" => nil,
        "mfa_expiration_timestamp" => nil,
        "domain" => "garmin.com"
      )
    end
  end

  describe ".from_hash" do
    it "reconstructs a token from a hash" do
      hash = {
        "oauth_token" => "tok",
        "oauth_token_secret" => "sec",
        "mfa_token" => "mfa",
        "mfa_expiration_timestamp" => "2026-01-01",
        "domain" => "garmin.cn"
      }

      token = described_class.from_hash(hash)

      expect(token.token).to eq("tok")
      expect(token.secret).to eq("sec")
      expect(token.mfa_token).to eq("mfa")
      expect(token.domain).to eq("garmin.cn")
    end
  end

  describe "#to_json" do
    it "produces valid JSON" do
      token = described_class.new(token: "t", secret: "s")
      parsed = JSON.parse(token.to_json)

      expect(parsed["oauth_token"]).to eq("t")
      expect(parsed["oauth_token_secret"]).to eq("s")
    end
  end
end
