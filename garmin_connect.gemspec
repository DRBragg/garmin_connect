# frozen_string_literal: true

require_relative "lib/garmin_connect/version"

Gem::Specification.new do |spec|
  spec.name = "garmin_connect"
  spec.version = GarminConnect::VERSION
  spec.authors = ["DRBragg"]
  spec.email = ["drbragg@gmail.com"]

  spec.summary = "Ruby client for the Garmin Connect API"
  spec.description = "A comprehensive Ruby wrapper for the Garmin Connect API, " \
                     "providing access to health, fitness, activity, and device data."
  spec.homepage = "https://github.com/drbragg/garmin_connect"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*", "LICENSE", "README.md", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "faraday-cookie_jar", "~> 0.0.7"
  spec.add_dependency "faraday-follow_redirects", "~> 0.3"
  spec.add_dependency "faraday-retry", "~> 2.0"
  spec.add_dependency "oauth", "~> 1.1"
end
