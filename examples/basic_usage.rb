#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "gasfree_sdk"
require "eth"

# Configure the SDK
GasfreeSdk.configure do |config|
  config.api_key = ENV["GASFREE_API_KEY"] || "your-api-key"
  config.api_secret = ENV["GASFREE_API_SECRET"] || "your-api-secret"
  config.api_endpoint = ENV["GASFREE_API_ENDPOINT"] || "https://open.gasfree.io/tron/"
end

# Check if we have real API credentials
if GasfreeSdk.config.api_key == "your-api-key"
  puts "WARNING: Using placeholder API credentials. Set GASFREE_API_KEY and " \
       "GASFREE_API_SECRET environment variables for real usage."
  puts "This example will demonstrate the SDK structure but API calls will fail.\n\n"
end

# Initialize client
client = GasfreeSdk.client

# Get supported tokens
puts "Supported Tokens:"
tokens = client.tokens
tokens.each do |token|
  puts "  #{token.symbol} (#{token.token_address})"
  puts "    Activation Fee: #{token.activate_fee}"
  puts "    Transfer Fee: #{token.transfer_fee}"
end

# Get service providers
puts "\nService Providers:"
providers = client.providers
providers.each do |provider|
  puts "  #{provider.name} (#{provider.address})"
  puts "    Max Pending Transfers: #{provider.config.max_pending_transfer}"
  puts "    Default Deadline: #{provider.config.default_deadline_duration}s"
end

# Create a new key pair for testing
key = Eth::Key.new
puts "\nTest Account:"
puts "  Address: #{key.address}"

# Get GasFree account info
puts "\nGasFree Account Info:"
begin
  account = client.address(key.address)
  puts "  GasFree Address: #{account.gas_free_address}"
  puts "  Active: #{account.active}"
  puts "  Nonce: #{account.nonce}"
  puts "  Assets:"
  account.assets.each do |asset|
    puts "    #{asset.token_symbol}: #{asset.frozen} frozen"
  end
rescue GasfreeSdk::APIError => e
  puts "  Error: #{e.message}"
end

# Example transfer request (this will fail as it's just a demo)
token = tokens.first
provider = providers.first

puts "\nSubmitting Transfer Request:"
begin
  # Create message to sign
  message = {
    token: token.token_address,
    service_provider: provider.address,
    user: key.address,
    receiver: "0x1234567890123456789012345678901234567890",
    value: "1000000",
    max_fee: token.transfer_fee,
    deadline: Time.now.to_i + provider.config.default_deadline_duration,
    version: 1,
    nonce: 0
  }

  # Sign the message
  sig = key.sign(Eth::Util.keccak256(message.to_json))

  # Create and submit transfer request
  request = GasfreeSdk::Models::TransferRequest.new(
    message.merge(sig: sig)
  )

  response = client.submit_transfer(request)
  puts "  Transfer ID: #{response.id}"
  puts "  State: #{response.state}"
  puts "  Estimated Fees:"
  puts "    Activation: #{response.estimated_activate_fee}"
  puts "    Transfer: #{response.estimated_transfer_fee}"

  # Monitor transfer status
  puts "\nMonitoring Transfer Status:"
  5.times do
    status = client.transfer_status(response.id)
    puts "  State: #{status.state}"
    puts "  Transaction Hash: #{status.txn_hash}" if status.txn_hash
    break if %w[SUCCEED FAILED].include?(status.state)

    sleep 2
  end
rescue GasfreeSdk::APIError => e
  puts "  Error (#{e.code}): #{e.message}"
end
