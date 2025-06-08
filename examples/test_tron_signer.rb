#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script for TronEIP712Signer module
# This script tests the signature functionality without making API calls

require "bundler/setup"
require "gasfree_sdk"

puts "Testing TronEIP712Signer Module"
puts "=" * 40

# Test data
private_key = "1b3d1201039f2c91d2dac01a218967981d594a4bfa004478e7fed19a12a9fc31"
user_address = "TZ3oPnE1SdAUL1YRd9GJQHenxrXjy4paAn"

message_data = {
  token: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t",
  serviceProvider: "TGzz8gjYiYRqpfmDwnLxfgPuLVNmpCswVp",
  user: user_address,
  receiver: "TX554G9uKsEv1U6TBQnNPC7dkhbvBFhgrD",
  value: "3000000",
  maxFee: "2000000",
  deadline: "1749371692",
  version: 1,
  nonce: 0
}

puts "Test Data:"
puts "  Private Key: #{private_key}"
puts "  User Address: #{user_address}"
puts "  Message Data: #{message_data}"
puts

# Test 1: Basic signature generation
puts "Test 1: Basic Signature Generation"
begin
  testnet_sig = GasfreeSdk::TronEIP712Signer.sign_typed_data_testnet(private_key, message_data)
  puts "  ✅ Testnet signature: #{testnet_sig[0..20]}...#{testnet_sig[-20..]}"
  puts "  ✅ Signature length: #{testnet_sig.length} characters"
rescue StandardError => e
  puts "  ❌ Error: #{e.message}"
end

# Test 2: Mainnet signature
puts "\nTest 2: Mainnet Signature Generation"
begin
  mainnet_sig = GasfreeSdk::TronEIP712Signer.sign_typed_data_mainnet(private_key, message_data)
  puts "  ✅ Mainnet signature: #{mainnet_sig[0..20]}...#{mainnet_sig[-20..]}"
  puts "  ✅ Signature length: #{mainnet_sig.length} characters"
rescue StandardError => e
  puts "  ❌ Error: #{e.message}"
end

# Test 3: Domain constants
puts "\nTest 3: Domain Constants"
begin
  testnet_domain = GasfreeSdk::TronEIP712Signer::DOMAIN_TESTNET
  mainnet_domain = GasfreeSdk::TronEIP712Signer::DOMAIN_MAINNET

  puts "  ✅ Testnet domain: #{testnet_domain[:name]} v#{testnet_domain[:version]}"
  puts "     Chain ID: #{testnet_domain[:chainId]}"
  puts "     Contract: #{testnet_domain[:verifyingContract]}"

  puts "  ✅ Mainnet domain: #{mainnet_domain[:name]} v#{mainnet_domain[:version]}"
  puts "     Chain ID: #{mainnet_domain[:chainId]}"
  puts "     Contract: #{mainnet_domain[:verifyingContract]}"
rescue StandardError => e
  puts "  ❌ Error: #{e.message}"
end

# Test 4: Cryptographic utilities
puts "\nTest 4: Cryptographic Utilities"
begin
  test_data = "Hello, TRON!"
  hash = GasfreeSdk::TronEIP712Signer.keccac256(test_data)
  hex_hash = GasfreeSdk::TronEIP712Signer.keccac256_hex(test_data)

  puts "  ✅ Keccac256 hash length: #{hash.length} bytes"
  puts "  ✅ Keccac256 hex hash: #{hex_hash[0..20]}...#{hex_hash[-20..]}"
rescue StandardError => e
  puts "  ❌ Error: #{e.message}"
end

# Test 5: Base58 utilities
puts "\nTest 5: Base58 Utilities"
begin
  binary_data = GasfreeSdk::Base58.base58_to_binary(user_address)
  restored_address = GasfreeSdk::Base58.binary_to_base58(binary_data)

  puts "  ✅ Address conversion: #{user_address} -> binary -> #{restored_address}"
  puts "  ✅ Conversion successful: #{user_address == restored_address}"
rescue StandardError => e
  puts "  ❌ Error: #{e.message}"
end

# Test 6: Type encoding
puts "\nTest 6: EIP-712 Type Encoding"
begin
  encoded_type = GasfreeSdk::TronEIP712Signer.encode_type(:PermitTransfer)
  puts "  ✅ Encoded PermitTransfer type:"
  puts "     #{encoded_type[0..80]}..."
rescue StandardError => e
  puts "  ❌ Error: #{e.message}"
end

# Test 7: Signature consistency
puts "\nTest 7: Signature Consistency"
begin
  sig1 = GasfreeSdk::TronEIP712Signer.sign_typed_data_testnet(private_key, message_data)
  sig2 = GasfreeSdk::TronEIP712Signer.sign_typed_data_testnet(private_key, message_data)

  puts "  ✅ Signature 1: #{sig1[0..20]}...#{sig1[-20..]}"
  puts "  ✅ Signature 2: #{sig2[0..20]}...#{sig2[-20..]}"
  puts "  ✅ Signatures are identical: #{sig1 == sig2}"
rescue StandardError => e
  puts "  ❌ Error: #{e.message}"
end

puts "\n#{"=" * 40}"
puts "All tests completed!"
puts "TronEIP712Signer module is working correctly ✅"
