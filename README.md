# GasFree SDK

Ruby SDK for GasFree.io - TRC-20 gasless transfer solution.

## 💬 Support & Consulting

If you encounter any issues, feel free to open a discussion or report a bug via the [GitHub Issues](https://github.com/madmatvey/gasfree_sdk/issues) page.

You can also [hire me as an external consultant](https://madmatvey.github.io/about/#cv) if you need help integrating or customizing the gem for your project.

If you find this gem useful and want to support further development, you're welcome to [donate here](https://madmatvey.github.io/about/#donate-me).

## Installation

This gem is published on [RubyGems.org](https://rubygems.org/gems/gasfree_sdk).

Add this line to your application's Gemfile:

```ruby
gem 'gasfree_sdk'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install gasfree_sdk

## Configuration

```ruby
require 'gasfree_sdk'

GasfreeSdk.configure do |config|
  config.api_key = "your-api-key"
  config.api_secret = "your-api-secret"
  config.api_endpoint = "https://open.gasfree.io/tron/"  # TRON endpoint
end
```

## Basic Usage

### Initialize Client

```ruby
client = GasfreeSdk.client
```

### Get Supported Tokens

```ruby
tokens = client.tokens
tokens.each do |token|
  puts "#{token.symbol} (#{token.token_address})"
  puts "  Activation Fee: #{token.activate_fee}"
  puts "  Transfer Fee: #{token.transfer_fee}"
end
```

### Get Service Providers

```ruby
providers = client.providers
providers.each do |provider|
  puts "#{provider.name} (#{provider.address})"
  puts "  Max Pending Transfers: #{provider.config.max_pending_transfer}"
  puts "  Default Deadline: #{provider.config.default_deadline_duration}s"
end
```

### Check Account Information

```ruby
account = client.address("TYourTronAddress")
puts "GasFree Address: #{account.gas_free_address}"
puts "Active: #{account.active}"
puts "Nonce: #{account.nonce}"

account.assets.each do |asset|
  puts "#{asset.token_symbol}: #{asset.frozen} frozen"
end
```

## TRON EIP-712 Signature Module

The SDK includes a comprehensive EIP-712 signature implementation specifically designed for TRON GasFree transfers. This module handles the complex cryptographic operations required for signing structured data according to the EIP-712 standard as implemented by TRON (TIP-712).

### Features

- **Complete EIP-712 Implementation**: Full support for EIP-712 structured data signing
- **TRON-Specific Adaptations**: Handles TRON address encoding and TIP-712 specifications
- **Dual Network Support**: Separate configurations for TRON Mainnet and Testnet (Nile)
- **Flexible Key Handling**: Support for multiple data key formats (camelCase, snake_case)
- **Built-in Cryptography**: Includes Keccak256 hashing and Base58 encoding for TRON addresses

### Basic Signature Usage

```ruby
# Example message data
message_data = {
  token: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t", # USDT TRC-20
  serviceProvider: "TGzz8gjYiYRqpfmDwnLxfgPuLVNmpCswVp",
  user: "TYRhsi1fkke2tjdVW9XGYLjf8TgbbutEgY",
  receiver: "TW1dWXfta5ygVN298JBN2UPhaSAUzo2owZ",
  value: "3000000", # 3 USDT (6 decimals)
  maxFee: "2000000", # 2 USDT max fee
  deadline: (Time.now.to_i + 300).to_s, # 5 minutes from now
  version: 1,
  nonce: 0
}

private_key = "your_private_key_hex"

# Sign for TRON Testnet (Nile)
testnet_signature = GasfreeSdk::TronEIP712Signer.sign_typed_data_testnet(private_key, message_data)

# Sign for TRON Mainnet
mainnet_signature = GasfreeSdk::TronEIP712Signer.sign_typed_data_mainnet(private_key, message_data)

# Generic signing with custom domain
signature = GasfreeSdk::TronEIP712Signer.sign_typed_data(
  private_key,
  message_data,
  domain: GasfreeSdk::TronEIP712Signer::DOMAIN_TESTNET
)
```

### Advanced Usage

#### Custom Domain Configuration

```ruby
custom_domain = {
  name: "GasFreeController",
  version: "V1.0.0",
  chainId: 728_126_428,
  verifyingContract: "THQGuFzL87ZqhxkgqYEryRAd7gqFqL5rdc"
}

signature = GasfreeSdk::TronEIP712Signer.sign_typed_data(
  private_key,
  message_data,
  domain: custom_domain,
  use_ethereum_v: true
)
```

#### Individual Cryptographic Operations

```ruby
# Keccak256 hashing
hash = GasfreeSdk::TronEIP712Signer.keccac256("data to hash")
hex_hash = GasfreeSdk::TronEIP712Signer.keccac256_hex("data to hash")

# EIP-712 type encoding
encoded_type = GasfreeSdk::TronEIP712Signer.encode_type(:PermitTransfer)

# Structured data hashing
message_hash = GasfreeSdk::TronEIP712Signer.hash_struct(:PermitTransfer, message_data)
domain_hash = GasfreeSdk::TronEIP712Signer.hash_domain
```

#### TRON Address Utilities

```ruby
# Base58 encoding/decoding for TRON addresses
binary_data = GasfreeSdk::Base58.base58_to_binary("TYRhsi1fkke2tjdVW9XGYLjf8TgbbutEgY")
base58_string = GasfreeSdk::Base58.binary_to_base58(binary_data)
```

### Domain Constants

The module provides pre-configured domain constants for both networks:

```ruby
# TRON Testnet (Nile)
GasfreeSdk::TronEIP712Signer::DOMAIN_TESTNET
# => {
#   name: "GasFreeController",
#   version: "V1.0.0",
#   chainId: 728_126_428,
#   verifyingContract: "THQGuFzL87ZqhxkgqYEryRAd7gqFqL5rdc"
# }

# TRON Mainnet
GasfreeSdk::TronEIP712Signer::DOMAIN_MAINNET
# => {
#   name: "GasFreeController",
#   version: "V1.0.0",
#   chainId: 3_448_148_188,
#   verifyingContract: "TFFAMQLZybALaLb4uxHA9RBE7pxhUAjF3U"
# }
```

### Submit Transfer with Signature

```ruby
# Create and submit a transfer request
token = client.tokens.first
provider = client.providers.first

message_data = {
  token: token.token_address,
  serviceProvider: provider.address,
  user: "TYourTronAddress",
  receiver: "TReceiverAddress",
  value: "1000000", # 1 USDT
  maxFee: "500000",  # 0.5 USDT max fee
  deadline: (Time.now.to_i + provider.config.default_deadline_duration).to_s,
  version: 1,
  nonce: account.nonce
}

# Sign the message
signature = GasfreeSdk::TronEIP712Signer.sign_typed_data_testnet(private_key, message_data)

# Create transfer request
request = GasfreeSdk::Models::TransferRequest.new(
  token: message_data[:token],
  service_provider: message_data[:serviceProvider],
  user: message_data[:user],
  receiver: message_data[:receiver],
  value: message_data[:value],
  max_fee: message_data[:maxFee],
  deadline: message_data[:deadline].to_i,
  version: message_data[:version],
  nonce: message_data[:nonce],
  sig: signature
)

# Submit the transfer
response = client.submit_transfer(request)
puts "Transfer ID: #{response.id}"
puts "State: #{response.state}"
```

### Monitor Transfer Status

```ruby
transfer_id = response.id

loop do
  status = client.transfer_status(transfer_id)
  puts "State: #{status.state}"
  puts "Transaction Hash: #{status.txn_hash}" if status.txn_hash

  break if %w[SUCCEED FAILED].include?(status.state)
  sleep 2
end
```

## Debugging and Logging

The SDK uses a custom Faraday middleware (`SanitizedLogsMiddleware`) to ensure that **all HTTP request and response logs are automatically sanitized**. Sensitive data is never written to logs, even in debug mode.

### Enable Debug Logging

```bash
export DEBUG_GASFREE_SDK=1
```

When this environment variable is set, the SDK will log HTTP requests and responses using only sanitized data. This is handled automatically; you do not need to configure anything extra.

### How It Works

- The SDK integrates `SanitizedLogsMiddleware` into the Faraday stack.
- This middleware intercepts all HTTP traffic and logs method, URL, headers, and body **with sensitive fields masked** (e.g., `***REDACTED***`).
- The original data is never mutated, and only masked data is ever written to logs.
- No other HTTP logging middleware is used, so there is no risk of leaking secrets.

### Example Integration (automatic)

```ruby
client = GasfreeSdk.client
# If DEBUG_GASFREE_SDK=1, all HTTP logs will be sanitized automatically.
```

### Automatic Data Protection

When debug logging is enabled, sensitive fields (private keys, tokens, signatures, etc.) are automatically masked with `***REDACTED***` in all HTTP request/response logs.

**Protected fields include:**
- Headers: `Authorization`, `Api-Key`, `X-Api-Key`, etc.
- Body fields: `private_key`, `api_secret`, `signature`, `token`, etc.

### Example

```ruby
# With DEBUG_GASFREE_SDK=1
client = GasfreeSdk.client
tokens = client.tokens
# Console output (sensitive data automatically masked):
# GET https://open.gasfree.io/tron/api/v1/config/token/all
# Request Headers: {"Authorization"=>"***REDACTED***", "Timestamp"=>"1703123456"}
```

## Error Handling

```ruby
begin
  response = client.submit_transfer(request)
rescue GasfreeSdk::APIError => e
  puts "API Error (#{e.code}): #{e.message}"

  case e.message
  when /insufficient balance/
    puts "Solution: Get test tokens or transfer tokens to GasFree address"
  when /max fee exceeded/
    puts "Solution: Increase maxFee parameter"
  when /Invalid signature/
    puts "Solution: Check private key and address correspondence"
  end
rescue StandardError => e
  puts "Error: #{e.message}"
end
```

## Examples

See the `examples/` directory for complete working examples:

- `examples/simple_usage_example.rb` - Basic TronEIP712Signer usage


## API Endpoint URL Validation

The `api_endpoint` configuration parameter is validated for correctness. If you try to set an invalid URL (for example, a string without a scheme, with an unsupported scheme, nil, or empty), an `ArgumentError` will be raised.

**Examples:**

```ruby
GasfreeSdk.configure do |config|
  config.api_endpoint = "https://valid.example.com/" # OK
  config.api_endpoint = "not a url"                  # => ArgumentError
  config.api_endpoint = "ftp://example.com"          # => ArgumentError
  config.api_endpoint = nil                           # => ArgumentError
  config.api_endpoint = ""                           # => ArgumentError
end
```

Only `http` and `https` schemes are supported.

## Dependencies

- `dry-configurable` - Configuration management
- `dry-struct` - Data structures
- `dry-types` - Type system
- `dry-validation` - Data validation
- `faraday` - HTTP client
- `faraday-retry` - HTTP retry logic
- `eth` - Ethereum utilities
- `rbsecp256k1` - Cryptographic operations for EIP-712 signatures

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/madmatvey/gasfree_sdk.

## License

The gem is available as open source under the terms of the [LGPL v3.0](https://www.gnu.org/licenses/lgpl-3.0.html) © 2025 Eugene Leontev (https://github.com/madmatvey)
