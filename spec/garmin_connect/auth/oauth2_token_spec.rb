# frozen_string_literal: true

require "spec_helper"

RSpec.describe GarminConnect::Auth::OAuth2Token do
  describe "#initialize" do
    it "stores all token attributes" do
      token = described_class.new(
        access_token: "access123",
        refresh_token: "refresh456",
        token_type: "Bearer",
        scope: "CONNECT_READ",
        jti: "jti789",
        expires_in: 3600,
        expires_at: 9_999_999_999,
        refresh_token_expires_in: 7200,
        refresh_token_expires_at: 9_999_999_999
      )

      expect(token.access_token).to eq("access123")
      expect(token.refresh_token).to eq("refresh456")
      expect(token.token_type).to eq("Bearer")
      expect(token.scope).to eq("CONNECT_READ")
      expect(token.jti).to eq("jti789")
      expect(token.expires_in).to eq(3600)
    end

    it "computes expires_at from expires_in when not provided" do
      now = Time.now.to_i
      token = described_class.new(access_token: "a", expires_in: 3600)

      expect(token.expires_at).to be_within(2).of(now + 3600)
    end
  end

  describe "#expired?" do
    it "returns false when token is still valid" do
      token = described_class.new(
        access_token: "a",
        expires_at: Time.now.to_i + 3600
      )

      expect(token).not_to be_expired
    end

    it "returns true when token has expired" do
      token = described_class.new(
        access_token: "a",
        expires_at: Time.now.to_i - 100
      )

      expect(token).to be_expired
    end
  end

  describe "#authorization_header" do
    it "returns the Bearer token string" do
      token = described_class.new(access_token: "mytoken", token_type: "bearer")

      expect(token.authorization_header).to eq("Bearer mytoken")
    end
  end

  describe "#to_s" do
    it "is an alias for authorization_header" do
      token = described_class.new(access_token: "mytoken")

      expect(token.to_s).to eq("Bearer mytoken")
    end
  end

  describe "#to_h" do
    it "returns a hash with all fields" do
      token = described_class.new(
        access_token: "a",
        refresh_token: "r",
        expires_in: 3600,
        expires_at: 1_000_000
      )
      hash = token.to_h

      expect(hash["access_token"]).to eq("a")
      expect(hash["refresh_token"]).to eq("r")
      expect(hash["expires_at"]).to eq(1_000_000)
    end
  end

  describe ".from_hash" do
    it "reconstructs a token from a hash" do
      hash = {
        "access_token" => "acc",
        "refresh_token" => "ref",
        "token_type" => "Bearer",
        "scope" => "CONNECT_READ",
        "jti" => "j",
        "expires_in" => 3600,
        "expires_at" => 9_999_999_999,
        "refresh_token_expires_in" => 7200,
        "refresh_token_expires_at" => 9_999_999_999
      }

      token = described_class.from_hash(hash)

      expect(token.access_token).to eq("acc")
      expect(token.scope).to eq("CONNECT_READ")
      expect(token.expires_at).to eq(9_999_999_999)
    end
  end
end
