# frozen_string_literal: true

require "spec_helper"
require "gasfree_sdk/sanitized_logs_middleware"
require "faraday"
require "stringio"

RSpec.describe GasfreeSdk::SanitizedLogsMiddleware do
  let(:sensitive_fields) { %w[authorization x-api-key private_key] }
  let(:mask) { "***REDACTED***" }
  let(:sanitizer) { GasfreeSdk::LogSanitizer.new(sensitive_fields: sensitive_fields, mask: mask) }
  let(:log_output) { StringIO.new }
  let(:logger) { Logger.new(log_output) }
  let(:app) do
    lambda { |env|
      # Simulate a Faraday response - this sets response data
      env[:response_headers] = { "Authorization" => "secret-token", "X-Api-Key" => "key" }
      env[:body] = { "private_key" => "should_hide", "normal" => "ok" }
      Faraday::Response.new(env)
    }
  end

  let(:middleware) { described_class.new(app, logger: logger, sanitizer: sanitizer) }

  it "masks sensitive data in request headers in logs" do
    env = {
      method: :get,
      url: "https://api.example.com",
      request_headers: { "Authorization" => "secret-token", "Normal" => "ok" },
      body: { "private_key" => "should_hide", "foo" => "bar" }
    }

    middleware.call(env)
    log_output.rewind
    log = log_output.read
    expect(log).to include(mask)
    expect(log).not_to include("secret-token")
    expect(log).to include("request: GET https://api.example.com")
  end

  it "masks sensitive data in response headers in logs and does not mutate original" do
    env = {
      method: :get,
      url: "https://api.example.com",
      request_headers: { "Authorization" => "secret-token", "Normal" => "ok" },
      body: { "private_key" => "should_hide", "foo" => "bar" }
    }

    response = middleware.call(env)
    log_output.rewind
    log = log_output.read
    expect(log).to include(mask)
    expect(log).not_to include("secret-token")
    expect(log).to include("response headers:")
    # Original headers not mutated
    expect(response.env[:response_headers]["Authorization"]).to eq("secret-token")
    expect(response.env[:response_headers]["X-Api-Key"]).to eq("key")
  end

  it "masks sensitive data in response body in logs and does not mutate original" do
    env = {
      method: :get,
      url: "https://api.example.com",
      request_headers: { "Authorization" => "secret-token", "Normal" => "ok" },
      body: { "private_key" => "should_hide", "foo" => "bar" }
    }

    response = middleware.call(env)
    log_output.rewind
    log = log_output.read
    expect(log).to include(mask)
    expect(log).not_to include("should_hide")
    expect(log).to include("response body:")
    # Original body not mutated
    expect(response.env[:body]["private_key"]).to eq("should_hide")
    expect(response.env[:body]["normal"]).to eq("ok")
  end
end
