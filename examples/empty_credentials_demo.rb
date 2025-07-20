#!/usr/bin/env ruby
# frozen_string_literal: true

# Demo of improved empty credentials handling
# This example shows how the SDK now properly handles empty string credentials

require "bundler/setup"
require "gasfree_sdk"

puts "=== GasFree SDK Empty Credentials Demo ==="
puts

# Test 1: Empty string API key
puts "Test 1: Empty API key"
begin
  GasfreeSdk.configure do |config|
    config.api_key = ""
    config.api_secret = "valid-secret"
    config.api_endpoint = "https://test.gasfree.io/"
  end

  client = GasfreeSdk.client
  client.tokens
rescue GasfreeSdk::ConfigurationError => e
  puts "✓ Caught ConfigurationError: #{e.message}"
end

puts

# Test 2: Empty string API secret
puts "Test 2: Empty API secret"
begin
  GasfreeSdk.configure do |config|
    config.api_key = "valid-key"
    config.api_secret = ""
    config.api_endpoint = "https://test.gasfree.io/"
  end

  client = GasfreeSdk.client
  client.tokens
rescue GasfreeSdk::ConfigurationError => e
  puts "✓ Caught ConfigurationError: #{e.message}"
end

puts

# Test 3: Both empty
puts "Test 3: Both credentials empty"
begin
  GasfreeSdk.configure do |config|
    config.api_key = ""
    config.api_secret = ""
    config.api_endpoint = "https://test.gasfree.io/"
  end

  client = GasfreeSdk.client
  client.tokens
rescue GasfreeSdk::ConfigurationError => e
  puts "✓ Caught ConfigurationError: #{e.message}"
end

puts

# Test 4: Nil credentials
puts "Test 4: Nil credentials"
begin
  GasfreeSdk.configure do |config|
    config.api_key = nil
    config.api_secret = nil
    config.api_endpoint = "https://test.gasfree.io/"
  end

  client = GasfreeSdk.client
  client.tokens
rescue GasfreeSdk::ConfigurationError => e
  puts "✓ Caught ConfigurationError: #{e.message}"
end

puts

# Test 5: Whitespace-only credentials
puts "Test 5: Whitespace-only credentials"
begin
  GasfreeSdk.configure do |config|
    config.api_key = "   "
    config.api_secret = "\t\n "
    config.api_endpoint = "https://test.gasfree.io/"
  end

  client = GasfreeSdk.client
  client.tokens
rescue GasfreeSdk::ConfigurationError => e
  puts "✓ Caught ConfigurationError: #{e.message}"
end

puts
puts "=== All tests completed successfully! ==="
puts "The SDK now properly validates credentials and provides clear error messages."
