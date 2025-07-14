require_relative "log_sanitizer"

module GasfreeSdk
  # Faraday middleware for sanitizing sensitive data before logging
  class LogSanitizerMiddleware < Faraday::Middleware
    private attr_reader :sanitizer
    def initialize(app, sanitizer: LogSanitizer.new)
      super(app)
      @sanitizer = sanitizer
    end

    def call(env)
      # Sanitize request headers only (body may be modified by other middleware)
      env[:request_headers] = sanitizer.call(env[:request_headers]) if env[:request_headers]

      @app.call(env).on_complete do |response_env|
        # Sanitize response headers and body
        if response_env[:response_headers]
          response_env[:response_headers] =
            sanitizer.call(response_env[:response_headers])
        end
        response_env[:body] = sanitizer.call(response_env[:body]) if response_env[:body]
      end
    end
  end
end
