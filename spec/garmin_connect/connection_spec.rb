# frozen_string_literal: true

require "spec_helper"

RSpec.describe GarminConnect::Connection do
  describe "#get" do
    it "makes an authenticated GET request" do
      stub_garmin_api(:get, "/test-service/data", response_body: { "key" => "value" })
      conn = build_connection

      result = conn.get("/test-service/data")

      expect(result).to eq("key" => "value")
    end

    it "includes the Authorization header" do
      stub = stub_garmin_api(:get, "/test-service/data", response_body: {})
      conn = build_connection

      conn.get("/test-service/data")

      expect(stub).to have_been_requested
      expect(WebMock).to have_requested(:get, "https://connectapi.garmin.com/test-service/data")
        .with(headers: { "Authorization" => "Bearer test-access-token" })
    end

    it "passes query parameters" do
      stub_request(:get, "https://connectapi.garmin.com/test-service/data")
        .with(query: { "date" => "2026-01-01" })
        .to_return(status: 200, body: "[]", headers: { "Content-Type" => "application/json" })

      conn = build_connection
      conn.get("/test-service/data", params: { "date" => "2026-01-01" })

      expect(WebMock).to have_requested(:get, "https://connectapi.garmin.com/test-service/data")
        .with(query: { "date" => "2026-01-01" })
    end
  end

  describe "#post" do
    it "sends a JSON body" do
      stub_request(:post, "https://connectapi.garmin.com/test-service/create")
        .to_return(status: 200, body: '{"id": 1}', headers: { "Content-Type" => "application/json" })

      conn = build_connection
      result = conn.post("/test-service/create", body: { "name" => "test" })

      expect(result).to eq("id" => 1)
      expect(WebMock).to have_requested(:post, "https://connectapi.garmin.com/test-service/create")
        .with(
          body: '{"name":"test"}',
          headers: { "Content-Type" => "application/json" }
        )
    end
  end

  describe "#delete" do
    it "makes an authenticated DELETE request" do
      stub_request(:delete, "https://connectapi.garmin.com/test-service/item/123")
        .to_return(status: 204, body: "")

      conn = build_connection
      result = conn.delete("/test-service/item/123")

      expect(result).to be_nil
    end
  end

  describe "error handling" do
    it "raises UnauthorizedError on 401" do
      stub_garmin_api(:get, "/fail", status: 401, response_body: { "error" => "unauthorized" })
      conn = build_connection

      expect { conn.get("/fail") }.to raise_error(GarminConnect::UnauthorizedError)
    end

    it "raises ForbiddenError on 403" do
      stub_garmin_api(:get, "/fail", status: 403, response_body: {})
      conn = build_connection

      expect { conn.get("/fail") }.to raise_error(GarminConnect::ForbiddenError)
    end

    it "raises TooManyRequestsError on 429" do
      stub_garmin_api(:get, "/fail", status: 429, response_body: {})
      conn = build_connection

      expect { conn.get("/fail") }.to raise_error(GarminConnect::TooManyRequestsError)
    end

    it "raises ServerError on 500+" do
      stub_garmin_api(:get, "/fail", status: 500, response_body: {})
      conn = build_connection

      expect { conn.get("/fail") }.to raise_error(GarminConnect::ServerError)
    end

    it "includes status and body in the error" do
      stub_garmin_api(:get, "/fail", status: 400, response_body: { "message" => "bad request" })
      conn = build_connection

      error = nil
      begin
        conn.get("/fail")
      rescue GarminConnect::BadRequestError => e
        error = e
      end

      expect(error.status).to eq(400)
      expect(error.body).to include("bad request")
    end
  end

  describe "token refresh" do
    it "refreshes the token when expired" do
      expired_oauth2 = build_oauth2_token(expires_at: Time.now.to_i - 100)
      fresh_oauth2 = build_oauth2_token(access_token: "fresh-token", expires_at: Time.now.to_i + 3600)

      allow(GarminConnect::Auth::SSO).to receive(:refresh).and_return(fresh_oauth2)

      stub_request(:get, "https://connectapi.garmin.com/test-service/data")
        .to_return(status: 200, body: '{"ok": true}', headers: { "Content-Type" => "application/json" })

      conn = build_connection(oauth2: expired_oauth2)
      conn.get("/test-service/data")

      expect(GarminConnect::Auth::SSO).to have_received(:refresh)
      expect(WebMock).to have_requested(:get, "https://connectapi.garmin.com/test-service/data")
        .with(headers: { "Authorization" => "Bearer fresh-token" })
    end
  end
end
