# frozen_string_literal: true

require "spec_helper"
require "gasfree_sdk/sanitized_logs_middleware"
require "faraday"
require "stringio"

RSpec.describe GasfreeSdk::SanitizedLogsMiddleware do # rubocop:disable RSpec/MultipleMemoizedHelpers
  let(:sensitive_fields) { %w[authorization x-api-key private_key] }
  let(:mask) { "***REDACTED***" }
  let(:sanitizer) { GasfreeSdk::LogSanitizer.new(sensitive_fields: sensitive_fields, mask: mask) }
  let(:log_output) { StringIO.new }
  let(:logger) { Logger.new(log_output) }
  let(:app) do
    lambda { |env|
      # Simulate a Faraday response - this sets response data
      env[:response_headers] =
        { "Authorization" => "secret-token", "X-Api-Key" => "key", "X-Normal" => "should_not_hide" }
      env[:body] = { "private_key" => "should_hide", "normal" => "should_not_hide" }
      Faraday::Response.new(env)
    }
  end
  let(:middleware) { described_class.new(app, logger: logger, sanitizer: sanitizer) }
  let(:env) do
    {
      method: :get,
      url: "https://api.example.com",
      request_headers: { "Authorization" => "secret-token", "Normal" => "should_not_hide" },
      body: { "private_key" => "should_hide", "foo" => "should_not_hide" }
    }
  end

  # rubocop:disable RSpec/MultipleMemoizedHelpers
  describe "request logging" do
    subject(:log) { log_output.read }

    before do
      middleware.call(env)
      log_output.rewind
    end

    it { is_expected.to include(mask) }
    it { is_expected.not_to include("secret-token") }
    it { is_expected.to include("request: GET https://api.example.com") }

    it "logs non-sensitive request header value" do
      expect(log).to include("should_not_hide")
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers

  # rubocop:disable RSpec/MultipleMemoizedHelpers
  describe "response logging" do
    subject(:log) { log_output.read }

    let!(:response) { middleware.call(env) }

    before { log_output.rewind }

    it { is_expected.to include(mask) }
    it { is_expected.not_to include("secret-token") }
    it { is_expected.to include("response headers:") }

    it "logs non-sensitive response header value" do
      expect(log).to include("should_not_hide")
    end

    it "does not mutate original response headers" do
      expect(response.env[:response_headers]["Authorization"]).to eq("secret-token")
      expect(response.env[:response_headers]["X-Api-Key"]).to eq("key")
      expect(response.env[:response_headers]["X-Normal"]).to eq("should_not_hide")
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers

  # rubocop:disable RSpec/MultipleMemoizedHelpers
  describe "response body logging" do
    subject(:log) { log_output.read }

    let!(:response) { middleware.call(env) }

    before { log_output.rewind }

    it { is_expected.to include(mask) }
    it { is_expected.not_to include("should_hide") }
    it { is_expected.to include("response body:") }

    it "logs non-sensitive response body value" do
      expect(log).to include("should_not_hide")
    end

    it "does not mutate original response body" do
      expect(response.env[:body]["private_key"]).to eq("should_hide")
      expect(response.env[:body]["normal"]).to eq("should_not_hide")
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers
end
