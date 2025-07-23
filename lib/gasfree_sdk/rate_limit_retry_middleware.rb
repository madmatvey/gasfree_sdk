# frozen_string_literal: true

require "time"

module GasfreeSdk
  # Middleware for handling HTTP 429 (Rate Limited) responses with intelligent retry logic
  # Supports parsing Retry-After headers and implements exponential backoff with jitter
  class RateLimitRetryMiddleware < Faraday::Middleware
    # Default configuration options
    DEFAULT_OPTIONS = {
      max_attempts: 5,
      base_delay: 1.0,
      max_delay: 60.0,
      exponential_base: 2,
      jitter_factor: 0.1,
      respect_retry_after: true
    }.freeze

    # @param app [#call] The Faraday app
    # @param options [Hash] Configuration options
    def initialize(app, options = {})
      super(app)
      @options = DEFAULT_OPTIONS.merge(options)
      @logger = GasfreeSdk.config.logger
    end

    # Process the request with rate limit retry logic
    # @param env [Faraday::Env] The request environment
    # @return [Faraday::Response] The response
    def call(env)
      attempt = 1

      loop do
        response = @app.call(env.dup)

        # If not rate limited or max attempts reached, return response
        return response unless should_retry?(response, attempt)

        # Calculate delay and sleep before retry
        delay = calculate_delay(response, attempt)
        log_retry_attempt(attempt, delay, response)

        sleep(delay)
        attempt += 1
      end
    end

    private

    # Determine if we should retry the request
    # @param response [Faraday::Response] The HTTP response
    # @param attempt [Integer] Current attempt number
    # @return [Boolean] Whether to retry
    def should_retry?(response, attempt)
      response.status == 429 && attempt < @options[:max_attempts]
    end

    # Calculate the delay before next retry attempt
    # @param response [Faraday::Response] The HTTP response
    # @param attempt [Integer] Current attempt number
    # @return [Float] Delay in seconds
    def calculate_delay(response, attempt)
      if @options[:respect_retry_after]
        retry_after_delay = parse_retry_after(response.headers["retry-after"])
        return apply_jitter(retry_after_delay) if retry_after_delay&.positive?
      end

      # Fallback to exponential backoff
      exponential_delay = @options[:base_delay] * (@options[:exponential_base]**(attempt - 1))
      capped_delay = [exponential_delay, @options[:max_delay]].min
      apply_jitter(capped_delay)
    end

    # Parse Retry-After header value
    # @param header_value [String, nil] The Retry-After header value
    # @return [Float, nil] Delay in seconds, or nil if unparseable
    def parse_retry_after(header_value)
      return nil if header_value.nil? || header_value.empty?

      case header_value.strip
      when /^\d+$/ # Seconds
        header_value.to_f
      when /^[A-Za-z]/ # HTTP date format
        begin
          retry_time = Time.parse(header_value)
          delay = retry_time - Time.now
          delay.positive? ? delay : nil
        rescue ArgumentError
          nil # Invalid date format
        end
      end
    end

    # Apply jitter to the delay to avoid thundering herd
    # @param base_delay [Float] Base delay in seconds
    # @return [Float] Delay with jitter applied
    def apply_jitter(base_delay)
      return 0.0 if base_delay <= 0

      jitter_range = base_delay * @options[:jitter_factor]
      jitter = rand(-jitter_range..jitter_range)
      [base_delay + jitter, 0.0].max
    end

    # Log retry attempt information
    # @param attempt [Integer] Current attempt number
    # @param delay [Float] Delay before retry
    # @param response [Faraday::Response] The rate limited response
    def log_retry_attempt(attempt, delay, response)
      retry_after = response.headers["retry-after"]

      @logger&.info(
        "Rate limited (429), retrying in #{delay.round(2)}s " \
        "(attempt #{attempt}/#{@options[:max_attempts] - 1}, " \
        "retry-after: #{retry_after || "not provided"})"
      )
    end
  end
end
