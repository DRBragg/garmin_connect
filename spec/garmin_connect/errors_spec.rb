# frozen_string_literal: true

require "spec_helper"

RSpec.describe GarminConnect::Error do
  it "inherits from StandardError" do
    expect(described_class.ancestors).to include(StandardError)
  end
end

RSpec.describe GarminConnect::HTTPError do
  it "stores status and body" do
    error = described_class.new("something broke", status: 500, body: "error details")

    expect(error.message).to eq("something broke")
    expect(error.status).to eq(500)
    expect(error.body).to eq("error details")
  end

  it "generates a default message from status" do
    error = described_class.new(status: 404)

    expect(error.message).to eq("HTTP 404")
  end
end

RSpec.describe GarminConnect::MFARequiredError do
  it "stores MFA HTML for later processing" do
    error = described_class.new("MFA needed", mfa_html: "<html>enter code</html>")

    expect(error.mfa_html).to include("enter code")
  end
end

RSpec.describe "error hierarchy" do
  it "maps HTTP errors correctly" do
    expect(GarminConnect::BadRequestError.ancestors).to include(GarminConnect::HTTPError)
    expect(GarminConnect::UnauthorizedError.ancestors).to include(GarminConnect::HTTPError)
    expect(GarminConnect::ForbiddenError.ancestors).to include(GarminConnect::HTTPError)
    expect(GarminConnect::NotFoundError.ancestors).to include(GarminConnect::HTTPError)
    expect(GarminConnect::TooManyRequestsError.ancestors).to include(GarminConnect::HTTPError)
    expect(GarminConnect::ServerError.ancestors).to include(GarminConnect::HTTPError)
  end

  it "all descend from GarminConnect::Error" do
    expect(GarminConnect::AuthenticationError.ancestors).to include(GarminConnect::Error)
    expect(GarminConnect::LoginError.ancestors).to include(GarminConnect::AuthenticationError)
    expect(GarminConnect::TokenExpiredError.ancestors).to include(GarminConnect::AuthenticationError)
  end
end
