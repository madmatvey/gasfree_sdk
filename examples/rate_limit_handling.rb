#!/usr/bin/env ruby
# frozen_string_literal: true

# Rate Limiting Handling Example
# ==============================
# This example demonstrates how the GasFree SDK handles HTTP 429 (Rate Limited) responses
# with intelligent retry logic including exponential backoff and jitter.

require "bundler/setup"
require "gasfree_sdk"

# Configure the SDK with custom rate limiting settings
GasfreeSdk.configure do |config|
  config.api_key = ENV["GASFREE_API_KEY"] || "your-api-key"
  config.api_secret = ENV["GASFREE_API_SECRET"] || "your-api-secret"
  config.api_endpoint = ENV["GASFREE_API_ENDPOINT"] || "https://open-test.gasfree.io/nile/"
  
  # Custom rate limit retry configuration
  config.rate_limit_retry_options = {
    max_attempts: 5,        # Maximum retry attempts for 429 errors
    base_delay: 1.0,        # Base delay in seconds
    max_delay: 60.0,        # Maximum delay cap in seconds
    exponential_base: 2,    # Exponential backoff multiplier
    jitter_factor: 0.1,     # Jitter factor to avoid thundering herd (10%)
    respect_retry_after: true # Honor Retry-After headers from server
  }
end

puts "GasFree SDK Rate Limiting Example"
puts "================================="
puts
puts "Rate limit retry configuration:"
puts "  Max attempts: #{GasfreeSdk.config.rate_limit_retry_options[:max_attempts]}"
puts "  Base delay: #{GasfreeSdk.config.rate_limit_retry_options[:base_delay]}s"
puts "  Max delay: #{GasfreeSdk.config.rate_limit_retry_options[:max_delay]}s"
puts "  Exponential base: #{GasfreeSdk.config.rate_limit_retry_options[:exponential_base]}"
puts "  Jitter factor: #{GasfreeSdk.config.rate_limit_retry_options[:jitter_factor]}"
puts "  Respect Retry-After: #{GasfreeSdk.config.rate_limit_retry_options[:respect_retry_after]}"
puts

# Check if we have real API credentials
if GasfreeSdk.config.api_key == "your-api-key"
  puts "WARNING: Using placeholder API credentials."
  puts "Set GASFREE_API_KEY and GASFREE_API_SECRET environment variables for real usage."
  puts "This example will demonstrate the retry logic structure."
  puts
end

# Initialize client
client = GasfreeSdk.client

begin
  puts "Fetching supported tokens (this may trigger rate limiting retry logic)..."
  
  # The SDK will automatically handle 429 responses with:
  # 1. Parse Retry-After header if present
  # 2. Apply exponential backoff with jitter if no header
  # 3. Retry up to max_attempts times
  # 4. Log retry attempts for monitoring
  
  tokens = client.tokens
  
  puts "✅ Successfully retrieved #{tokens.length} tokens:"
  tokens.first(3).each do |token|
    puts "  • #{token.symbol} (#{token.token_address[0..10]}...)"
  end
  
rescue GasfreeSdk::RateLimitError => e
  puts "❌ Rate limit exceeded after all retry attempts:"
  puts "   Error: #{e.message}"
  puts "   Code: #{e.code}"
  puts "   Suggestion: Wait longer before making requests or contact API support"
  
rescue GasfreeSdk::AuthenticationError => e
  puts "❌ Authentication failed:"
  puts "   Error: #{e.message}"
  puts "   Check your API credentials"
  
rescue GasfreeSdk::APIError => e
  puts "❌ API error occurred:"
  puts "   Error: #{e.message}"
  puts "   Code: #{e.code}"
  puts "   Reason: #{e.reason}"
  
rescue StandardError => e
  puts "❌ Unexpected error:"
  puts "   #{e.class}: #{e.message}"
end

puts
puts "Rate Limiting Best Practices:"
puts "=============================="
puts "1. The SDK automatically handles 429 responses with intelligent retry"
puts "2. Retry-After headers from the server are respected when present"
puts "3. Exponential backoff with jitter prevents thundering herd effects"
puts "4. Configure max_attempts and delays based on your application needs"
puts "5. Monitor retry logs to optimize your request patterns"
puts "6. Consider implementing client-side rate limiting for high-volume apps"
