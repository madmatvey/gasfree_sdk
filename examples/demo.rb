#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "gasfree_sdk"

puts "GasFree SDK Demonstration"
puts "========================="

# Show SDK version
puts "SDK Version: #{GasfreeSdk::VERSION}"

# Configure the SDK
GasfreeSdk.configure do |config|
  config.api_key = "demo-api-key"
  config.api_secret = "demo-api-secret"
  config.api_endpoint = "https://demo.gasfree.io/"
end

puts "Configuration:"
puts "  API Endpoint: #{GasfreeSdk.config.api_endpoint}"
puts "  API Key: #{GasfreeSdk.config.api_key[0..3]}..."
puts "  Chain ID: #{GasfreeSdk.config.default_chain_id}"
puts ""

# Show client creation
client = GasfreeSdk.client
puts "Client created: #{client.class}"
puts ""

# Demonstrate model creation
puts "Model Examples:"
puts "==============="

# Token model
token = GasfreeSdk::Models::Token.new(
  token_address: "0x1234567890123456789012345678901234567890",
  created_at: "2024-01-01T00:00:00Z",
  updated_at: "2024-01-01T00:00:00Z",
  activate_fee: "1000000",
  transfer_fee: "500000",
  supported: true,
  symbol: "USDT",
  decimal: 6
)

puts "Token:"
puts "  Symbol: #{token.symbol}"
puts "  Address: #{token.token_address}"
puts "  Activation Fee: #{token.activate_fee}"
puts "  Transfer Fee: #{token.transfer_fee}"
puts ""

# Provider model
provider = GasfreeSdk::Models::Provider.new(
  address: "0x1234567890123456789012345678901234567890",
  name: "Demo Provider",
  icon: "",
  website: "https://demo.provider.com",
  config: {
    max_pending_transfer: 1,
    min_deadline_duration: 60,
    max_deadline_duration: 600,
    default_deadline_duration: 180
  }
)

puts "Provider:"
puts "  Name: #{provider.name}"
puts "  Address: #{provider.address}"
puts "  Max Pending: #{provider.config.max_pending_transfer}"
puts "  Default Deadline: #{provider.config.default_deadline_duration}s"
puts ""

# Transfer request model
transfer_request = GasfreeSdk::Models::TransferRequest.new(
  token: token.token_address,
  service_provider: provider.address,
  user: "0x1111111111111111111111111111111111111111",
  receiver: "0x2222222222222222222222222222222222222222",
  value: "1000000",
  max_fee: "100000",
  deadline: Time.now.to_i + 180,
  version: 1,
  nonce: 0,
  sig: "0x" + "a" * 128
)

puts "Transfer Request:"
puts "  Token: #{transfer_request.token}"
puts "  Provider: #{transfer_request.service_provider}"
puts "  User: #{transfer_request.user}"
puts "  Receiver: #{transfer_request.receiver}"
puts "  Value: #{transfer_request.value}"
puts "  Max Fee: #{transfer_request.max_fee}"
puts "  Deadline: #{Time.at(transfer_request.deadline)}"
puts "  Version: #{transfer_request.version}"
puts ""

# Transfer response model
transfer_response = GasfreeSdk::Models::TransferResponse.new(
  id: "demo-transfer-id",
  created_at: "2024-01-01T00:00:00Z",
  updated_at: "2024-01-01T00:00:00Z",
  account_address: transfer_request.user,
  gas_free_address: "0x3333333333333333333333333333333333333333",
  provider_address: provider.address,
  target_address: transfer_request.receiver,
  token_address: token.token_address,
  amount: transfer_request.value,
  max_fee: transfer_request.max_fee,
  signature: transfer_request.sig,
  nonce: transfer_request.nonce,
  expired_at: "2024-01-01T00:03:00Z",
  state: "WAITING"
)

puts "Transfer Response:"
puts "  ID: #{transfer_response.id}"
puts "  State: #{transfer_response.state}"
puts "  Amount: #{transfer_response.amount}"
puts "  Expires At: #{transfer_response.expired_at}"
puts ""

# Show error classes
puts "Error Classes:"
puts "=============="
puts "  Base: #{GasfreeSdk::Error}"
puts "  Authentication: #{GasfreeSdk::AuthenticationError}"
puts "  API: #{GasfreeSdk::APIError}"
puts "  Deadline Exceeded: #{GasfreeSdk::DeadlineExceededError}"
puts "  Invalid Signature: #{GasfreeSdk::InvalidSignatureError}"
puts ""

puts "Demo completed successfully!"
puts ""
puts "For real usage:"
puts "1. Set GASFREE_API_KEY and GASFREE_API_SECRET environment variables"
puts "2. Use examples/basic_usage.rb for a complete workflow example"
puts "3. See README.md for full documentation" 