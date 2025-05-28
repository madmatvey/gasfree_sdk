#!/usr/bin/env ruby
# frozen_string_literal: true

# GasFree SDK Simple Usage Example with TronEIP712Signer
# =====================================================
# This example demonstrates how to use the TronEIP712Signer module
# to sign EIP-712 messages for TRON GasFree transfers.

require "bundler/setup"
require "gasfree_sdk"

# Configure the SDK
GasfreeSdk.configure do |config|
  config.api_key = ENV["GASFREE_API_KEY"] || "your-api-key"
  config.api_secret = ENV["GASFREE_API_SECRET"] || "your-api-secret"
  config.api_endpoint = ENV["GASFREE_API_ENDPOINT"] || "https://open.gasfree.io/tron/"
end

puts "GasFree SDK with TronEIP712Signer Example"
puts "=" * 50

# Example private key and address (for demonstration only)
private_key = "1b3d1201039f2c91d2dac01a218967981d594a4bfa004478e7fed19a12a9fc31"
user_address = "TZ3oPnE1SdAUL1YRd9GJQHenxrXjy4paAn"

puts "Using example key pair:"
puts "  Private Key: #{private_key}"
puts "  TRON Address: #{user_address}"
puts

# Example message data for signing
message_data = {
  token: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t", # USDT TRC-20
  serviceProvider: "TGzz8gjYiYRqpfmDwnLxfgPuLVNmpCswVp",
  user: user_address,
  receiver: "TX554G9uKsEv1U6TBQnNPC7dkhbvBFhgrD",
  value: "3000000", # 3 USDT (6 decimals)
  maxFee: "2000000", # 2 USDT max fee
  deadline: (Time.now.to_i + 300).to_s, # 5 minutes from now
  version: 1,
  nonce: 0
}

puts "Message to sign:"
message_data.each do |key, value|
  puts "  #{key}: #{value}"
end
puts

# Sign for testnet
puts "Signing for TRON Testnet (Nile):"
testnet_signature = GasfreeSdk::TronEIP712Signer.sign_typed_data_testnet(private_key, message_data)
puts "  Signature: #{testnet_signature}"
puts "  Length: #{testnet_signature.length} characters"
puts

# Sign for mainnet
puts "Signing for TRON Mainnet:"
mainnet_signature = GasfreeSdk::TronEIP712Signer.sign_typed_data_mainnet(private_key, message_data)
puts "  Signature: #{mainnet_signature}"
puts "  Length: #{mainnet_signature.length} characters"
puts

# Show domain information
puts "Domain Information:"
puts "  Testnet Domain:"
GasfreeSdk::TronEIP712Signer::DOMAIN_TESTNET.each do |key, value|
  puts "    #{key}: #{value}"
end
puts
puts "  Mainnet Domain:"
GasfreeSdk::TronEIP712Signer::DOMAIN_MAINNET.each do |key, value|
  puts "    #{key}: #{value}"
end
puts

# Example of using with GasFree SDK client
if GasfreeSdk.config.api_key == "your-api-key"
  puts "Set GASFREE_API_KEY and GASFREE_API_SECRET to test with real API"
else
  puts "Creating transfer request with signed message:"

  begin
    GasfreeSdk.client

    # Create transfer request with the signature
    GasfreeSdk::Models::TransferRequest.new(
      token: message_data[:token],
      service_provider: message_data[:serviceProvider],
      user: message_data[:user],
      receiver: message_data[:receiver],
      value: message_data[:value],
      max_fee: message_data[:maxFee],
      deadline: message_data[:deadline].to_i,
      version: message_data[:version],
      nonce: message_data[:nonce],
      sig: testnet_signature
    )

    puts "  Transfer request created successfully!"
    puts "  Ready to submit to GasFree API"
  rescue StandardError => e
    puts "  Error creating request: #{e.message}"
  end
end

puts "\nExample completed!"
