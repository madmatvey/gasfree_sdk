# frozen_string_literal: true

require "spec_helper"

RSpec.describe GasfreeSdk::RateLimitRetryMiddleware do
  let(:middleware) { described_class.new(->(env) { env }, options) }
  let(:options) { {} }
  let(:env) { double("env") }
  let(:logger) { instance_double(Logger) }

  before do
    allow(env).to receive(:dup).and_return(env)
    allow(GasfreeSdk.config).to receive(:logger).and_return(logger)
    allow(logger).to receive(:info)
  end

  describe "#initialize" do
    it "sets default options when none provided" do
      middleware = described_class.new(->(env) { env })
      expect(middleware.instance_variable_get(:@options)).to include(
        max_attempts: 5,
        base_delay: 1.0,
        max_delay: 60.0,
        exponential_base: 2,
        jitter_factor: 0.1,
        respect_retry_after: true
      )
    end

    it "merges custom options with defaults" do
      custom_options = { max_attempts: 3, base_delay: 2.0 }
      middleware = described_class.new(->(env) { env }, custom_options)
      options = middleware.instance_variable_get(:@options)

      expect(options[:max_attempts]).to eq(3)
      expect(options[:base_delay]).to eq(2.0)
      expect(options[:max_delay]).to eq(60.0) # default preserved
    end
  end

  describe "#call" do
    let(:success_response) { double("response", status: 200) }
    let(:rate_limit_response) { double("response", status: 429, headers: {}) }

    context "when response is successful" do
      it "returns response immediately without retry" do
        app = double("app")
        allow(app).to receive(:call).with(env).and_return(success_response)

        middleware = described_class.new(app, options)
        result = middleware.call(env)

        expect(result).to eq(success_response)
        expect(app).to have_received(:call).once
      end
    end

    context "when response is rate limited (429)" do
      let(:app) { double("app") }
      let(:options) { { max_attempts: 3, base_delay: 0.01, jitter_factor: 0 } }

      before do
        allow(middleware).to receive(:sleep) # Mock sleep to speed up tests
      end

      it "retries the request" do
        allow(app).to receive(:call).with(env)
                                    .and_return(rate_limit_response, rate_limit_response, success_response)

        middleware = described_class.new(app, options)
        result = middleware.call(env)

        expect(result).to eq(success_response)
        expect(app).to have_received(:call).exactly(3).times
      end

      it "stops retrying after max attempts" do
        allow(app).to receive(:call).with(env).and_return(rate_limit_response)

        middleware = described_class.new(app, options)
        result = middleware.call(env)

        expect(result).to eq(rate_limit_response)
        expect(app).to have_received(:call).exactly(3).times # max_attempts
      end

      it "logs retry attempts" do
        allow(app).to receive(:call).with(env)
                                    .and_return(rate_limit_response, success_response)

        middleware = described_class.new(app, options)
        middleware.call(env)

        expect(logger).to have_received(:info).with(
          a_string_matching(%r{Rate limited \(429\), retrying in .* \(attempt 1/2})
        )
      end
    end
  end

  describe "#parse_retry_after" do
    it "parses numeric seconds correctly" do
      result = middleware.send(:parse_retry_after, "60")
      expect(result).to eq(60.0)
    end

    it "parses HTTP date format correctly" do
      future_time = Time.now + 30
      date_string = future_time.httpdate

      result = middleware.send(:parse_retry_after, date_string)
      expect(result).to be_within(1).of(30)
    end

    it "handles invalid date format gracefully" do
      result = middleware.send(:parse_retry_after, "invalid-date")
      expect(result).to be_nil
    end

    it "handles nil input" do
      result = middleware.send(:parse_retry_after, nil)
      expect(result).to be_nil
    end

    it "handles empty string" do
      result = middleware.send(:parse_retry_after, "")
      expect(result).to be_nil
    end

    it "returns nil for past dates" do
      past_time = Time.now - 30
      date_string = past_time.httpdate

      result = middleware.send(:parse_retry_after, date_string)
      expect(result).to be_nil
    end
  end

  describe "#calculate_delay" do
    let(:response) { double("response", headers: {}) }
    let(:options) { { base_delay: 1.0, max_delay: 10.0, exponential_base: 2, jitter_factor: 0 } }

    context "with Retry-After header" do
      let(:options) { super().merge(respect_retry_after: true) }

      it "uses Retry-After value when present and valid" do
        allow(response).to receive(:headers).and_return({ "retry-after" => "5" })

        delay = middleware.send(:calculate_delay, response, 1)
        expect(delay).to eq(5.0)
      end

      it "falls back to exponential backoff when Retry-After is invalid" do
        allow(response).to receive(:headers).and_return({ "retry-after" => "invalid" })

        delay = middleware.send(:calculate_delay, response, 2)
        expect(delay).to eq(2.0) # base_delay * exponential_base^(attempt-1) = 1.0 * 2^1
      end
    end

    context "without respecting Retry-After" do
      let(:options) { super().merge(respect_retry_after: false) }

      it "uses exponential backoff" do
        allow(response).to receive(:headers).and_return({ "retry-after" => "5" })

        delay = middleware.send(:calculate_delay, response, 3)
        expect(delay).to eq(4.0) # 1.0 * 2^(3-1) = 4.0
      end
    end

    it "caps delay at max_delay" do
      delay = middleware.send(:calculate_delay, response, 10) # Large attempt number
      expect(delay).to eq(10.0) # Should be capped at max_delay
    end
  end

  describe "#apply_jitter" do
    let(:options) { { jitter_factor: 0.1 } }

    it "returns 0 for non-positive delays" do
      expect(middleware.send(:apply_jitter, 0)).to eq(0.0)
      expect(middleware.send(:apply_jitter, -5)).to eq(0.0)
    end

    it "applies jitter within expected range" do
      base_delay = 10.0
      jittered_delays = 100.times.map { middleware.send(:apply_jitter, base_delay) }

      # All values should be within the jitter range
      min_expected = base_delay * (1 - 0.1)
      max_expected = base_delay * (1 + 0.1)

      expect(jittered_delays).to all(be_between(min_expected, max_expected))
    end

    it "with zero jitter factor returns original delay" do
      options[:jitter_factor] = 0
      result = middleware.send(:apply_jitter, 5.0)
      expect(result).to eq(5.0)
    end
  end

  describe "#should_retry?" do
    let(:options) { { max_attempts: 3 } }

    it "returns true for 429 status within max attempts" do
      response = double("response", status: 429)
      expect(middleware.send(:should_retry?, response, 1)).to be true
      expect(middleware.send(:should_retry?, response, 2)).to be true
    end

    it "returns false when max attempts reached" do
      response = double("response", status: 429)
      expect(middleware.send(:should_retry?, response, 3)).to be false
    end

    it "returns false for non-429 status codes" do
      response = double("response", status: 500)
      expect(middleware.send(:should_retry?, response, 1)).to be false

      response = double("response", status: 200)
      expect(middleware.send(:should_retry?, response, 1)).to be false
    end
  end
end
