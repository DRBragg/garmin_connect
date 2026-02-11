# frozen_string_literal: true

module GarminConnect
  class Error < StandardError; end

  # Authentication & login errors
  class AuthenticationError < Error; end
  class LoginError < AuthenticationError; end
  class MFARequiredError < AuthenticationError
    attr_reader :mfa_html

    def initialize(message = "MFA code required", mfa_html: nil)
      @mfa_html = mfa_html
      super(message)
    end
  end

  class TokenExpiredError < AuthenticationError; end

  # HTTP response errors
  class HTTPError < Error
    attr_reader :status, :body

    def initialize(message = nil, status: nil, body: nil)
      @status = status
      @body = body
      super(message || "HTTP #{status}")
    end
  end

  class BadRequestError < HTTPError; end
  class UnauthorizedError < HTTPError; end
  class ForbiddenError < HTTPError; end
  class NotFoundError < HTTPError; end
  class TooManyRequestsError < HTTPError; end
  class ServerError < HTTPError; end

  # Response parsing errors
  class ParseError < Error; end

  # Maps HTTP status codes to error classes
  HTTP_ERRORS = {
    400 => BadRequestError,
    401 => UnauthorizedError,
    403 => ForbiddenError,
    404 => NotFoundError,
    429 => TooManyRequestsError
  }.freeze
end
