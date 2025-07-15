# frozen_string_literal: true

require_relative "log_sanitizer"
require "logger"

module GasfreeSdk
  # Faraday middleware for logging HTTP requests and responses with sanitized data
  class SanitizedLogsMiddleware < Faraday::Middleware
    # @param app [#call] The next middleware in the stack
    # @param logger [Logger] Logger instance (default: Logger.new($stdout))
    # @param sanitizer [LogSanitizer] LogSanitizer instance (default: LogSanitizer.new)
    def initialize(app, logger: Logger.new($stdout), sanitizer: LogSanitizer.new)
      super(app)
      @logger = logger
      @sanitizer = sanitizer
    end

    # Faraday middleware entry point
    # @param env [Faraday::Env] Faraday request/response environment
    # @return [Faraday::Response]
    def call(env)
      log_request(env)
      @app.call(env).on_complete do |response_env|
        log_response(response_env)
      end
    end

    private

    attr_reader :logger, :sanitizer

    def log_request(env) # rubocop:disable Metrics/AbcSize
      logger.info("request: #{env[:method].to_s.upcase} #{env[:url]}")
      sanitized_headers = sanitizer.call(env[:request_headers]) if env[:request_headers]
      logger.info("request headers: #{sanitized_headers}") if sanitized_headers
      return unless env[:body]

      sanitized_body = sanitizer.call(env[:body])
      logger.info("request body: #{sanitized_body}")
    end

    def log_response(env)
      logger.info("response: Status #{env.status}")
      sanitized_headers = sanitizer.call(env[:response_headers]) if env[:response_headers]
      logger.info("response headers: #{sanitized_headers}") if sanitized_headers
      return unless env[:body]

      sanitized_body = sanitizer.call(env[:body])
      logger.info("response body: #{sanitized_body}")
    end
  end
end
