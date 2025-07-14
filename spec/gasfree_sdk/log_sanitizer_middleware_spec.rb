# frozen_string_literal: true

require "spec_helper"
require "gasfree_sdk/log_sanitizer_middleware"
require "faraday"

RSpec.describe GasfreeSdk::LogSanitizerMiddleware do
  let(:sensitive_fields) { %w[authorization x-api-key private_key] }
  let(:mask) { "***REDACTED***" }
  let(:sanitizer) { GasfreeSdk::LogSanitizer.new(sensitive_fields: sensitive_fields, mask: mask) }
  let(:app) do
    lambda { |env|
      # Simulate a Faraday response - this sets response data
      env[:response_headers] = { "Authorization" => "secret-token", "X-Api-Key" => "key" }
      env[:body] = { "private_key" => "should_hide", "normal" => "ok" }
      Faraday::Response.new(env)
    }
  end

  let(:middleware) { described_class.new(app, sanitizer: sanitizer) }

  it "masks sensitive data in request headers" do
    env = {
      request_headers: { "Authorization" => "secret-token", "Normal" => "ok" },
      body: { "private_key" => "should_hide", "foo" => "bar" }
    }

    middleware.call(env)

    expect(env[:request_headers]["Authorization"]).to eq(mask)
    expect(env[:request_headers]["Normal"]).to eq("ok")
  end

  it "masks sensitive data in response headers" do
    env = {
      request_headers: { "Authorization" => "secret-token", "Normal" => "ok" },
      body: { "private_key" => "should_hide", "foo" => "bar" }
    }

    response = middleware.call(env)

    expect(response.env[:response_headers]["Authorization"]).to eq(mask)
    expect(response.env[:response_headers]["X-Api-Key"]).to eq(mask)
  end

  it "masks sensitive data in response body" do
    env = {
      request_headers: { "Authorization" => "secret-token", "Normal" => "ok" },
      body: { "private_key" => "should_hide", "foo" => "bar" }
    }

    response = middleware.call(env)

    expect(response.env[:body]["private_key"]).to eq(mask)
    expect(response.env[:body]["normal"]).to eq("ok")
  end
end
