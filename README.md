# GasfreeSdk

Ruby SDK for interacting with the GasFree.io API, enabling gasless transfers of TRC-20/ERC-20 tokens.

## Features

- Supports gasless transfers of TRC-20/ERC-20 tokens
- Handles both Ethereum and TRON address formats
- Provides a clean, Ruby-like interface to the GasFree API
- Built with dry-rb for robust type checking and validation
- Comprehensive RSpec test coverage
- Thread-safe configuration
- Automatic data transformation between API and model formats

## Version Compatibility

- **Ruby**: Requires Ruby 3.3.0 or higher
- **API**: Compatible with GasFree.io API v1
- **Networks**: Supports both Ethereum and TRON networks
- **Address Formats**: Validates and handles both Ethereum (`0x...`) and TRON (`T...`) addresses

## Recent Updates

- **v1.x**: Added TRON address format support
- **v1.x**: Improved API response data transformation
- **v1.x**: Enhanced error handling and validation
- **v1.x**: Fixed compatibility with TRON testnet endpoints

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'gasfree_sdk'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install gasfree_sdk
```

## Address Format Support

The SDK supports both Ethereum and TRON address formats:

- **Ethereum addresses**: `0x` followed by 40 hexadecimal characters (e.g., `0x1234567890123456789012345678901234567890`)
- **TRON addresses**: `T` followed by 33 base58 characters (e.g., `TN3W4H6rK2ce4vX9YnFQHwKENnHjoxb3m9`)

**Important**: When using TRON endpoints (like `https://open-test.gasfree.io/nile/`), you must use TRON-format addresses. The SDK will validate address formats and raise errors for mismatched formats.

### TRON Address Generation

The SDK includes the `eth` gem for Ethereum address generation, but for TRON addresses, you'll need to use appropriate TRON libraries or pre-generated addresses. For development and testing, you can use known TRON testnet addresses.

```ruby
# Example TRON testnet addresses for development
user_address = "TN3W4H6rK2ce4vX9YnFQHwKENnHjoxb3m9"
receiver_address = "TAjfKbDLsNcJSf6RJZZ2i6UoqM4iMq22Y2"
```

## Configuration

Configure the SDK with your API credentials:

```ruby
GasfreeSdk.configure do |config|
  config.api_key = "your-api-key"
  config.api_secret = "your-api-secret"
  config.api_endpoint = "https://open.gasfree.io/tron/" # Optional, defaults to mainnet
  config.default_chain_id = 1 # Optional, defaults to Ethereum mainnet
end
```

### API Endpoints

The SDK supports different API endpoints depending on your needs:

**Production (Mainnet):**
```ruby
config.api_endpoint = "https://open.gasfree.io/tron/" # Default
```

**Testnet (Nile):**
```ruby
config.api_endpoint = "https://open-test.gasfree.io/nile/"
# or without trailing slash
config.api_endpoint = "https://open-test.gasfree.io/nile"
```

**Custom endpoint:**
```ruby
config.api_endpoint = "https://your-custom-endpoint.com/api/"
```

**Note:** The SDK automatically handles URL path construction regardless of whether you include a trailing slash in the endpoint URL. API requests will be correctly routed to the specified endpoint with the appropriate API paths appended.

## Usage

### Initialize Client

```ruby
client = GasfreeSdk.client
```

### Get Supported Tokens

```ruby
tokens = client.tokens
tokens.each do |token|
  puts "Token: #{token.symbol}"
  puts "Address: #{token.token_address}"
  puts "Activation Fee: #{token.activate_fee}"
  puts "Transfer Fee: #{token.transfer_fee}"
end
```

### Get Service Providers

Service providers are entities that facilitate gasless transfers. Each provider has its own configuration and constraints:

```ruby
providers = client.providers
providers.each do |provider|
  puts "Provider: #{provider.name}"
  puts "Address: #{provider.address}"
  puts "Website: #{provider.website}"
  puts "Icon: #{provider.icon}"
  
  # Provider configuration constraints
  config = provider.config
  puts "Max Pending Transfers: #{config.max_pending_transfer}"
  puts "Min Deadline Duration: #{config.min_deadline_duration}s"
  puts "Max Deadline Duration: #{config.max_deadline_duration}s"
  puts "Default Deadline Duration: #{config.default_deadline_duration}s"
end
```

When creating transfer requests, you must respect the provider's constraints:
- Choose a deadline between `min_deadline_duration` and `max_deadline_duration`
- Ensure you don't exceed `max_pending_transfer` concurrent transfers
- Use `default_deadline_duration` as a safe default deadline

Example of using provider constraints:

```ruby
provider = providers.first
deadline = Time.now.to_i + provider.config.default_deadline_duration

request = GasfreeSdk::Models::TransferRequest.new(
  # ... other fields ...
  service_provider: provider.address,
  deadline: deadline
)
```

### Get GasFree Account Info

```ruby
# Use TRON address format for TRON endpoints
tron_address = "TN3W4H6rK2ce4vX9YnFQHwKENnHjoxb3m9"
account = client.address(tron_address)
puts "GasFree Address: #{account.gas_free_address}"
puts "Active: #{account.active}"
puts "Nonce: #{account.nonce}"

account.assets.each do |asset|
  puts "Token: #{asset.token_symbol}"
  puts "Frozen Amount: #{asset.frozen}"
end
```

**Note**: The address format must match the blockchain network you're targeting. Use TRON addresses (`T...`) for TRON endpoints and Ethereum addresses (`0x...`) for Ethereum endpoints.

### Submit GasFree Transfer

```ruby
# Example using TRON addresses for TRON testnet
request = GasfreeSdk::Models::TransferRequest.new(
  token: "TXYZopYRdj2D9XRtbG411XZZ3kM5VkAeBf", # TRON token address
  service_provider: "TKtWbdzEq5ss9vTS9kwRhBp5mXmBfBns3E", # TRON provider address
  user: "TN3W4H6rK2ce4vX9YnFQHwKENnHjoxb3m9", # User's TRON address
  receiver: "TAjfKbDLsNcJSf6RJZZ2i6UoqM4iMq22Y2", # Recipient TRON address
  value: "1000000", # Amount in smallest unit (6 decimals for USDT)
  max_fee: "100000", # Maximum fee in smallest unit
  deadline: Time.now.to_i + 180, # 3 minutes from now
  version: 1,
  nonce: 0,
  sig: "0x..." # User's signature (see signing section below)
)

response = client.submit_transfer(request)
puts "Transfer ID: #{response.id}"
puts "State: #{response.state}"
```

**Important**: For TRON transactions, you'll need to implement TRON-specific signing. The SDK includes Ethereum signing capabilities via the `eth` gem, but TRON requires different cryptographic operations. Consider using specialized TRON libraries for production applications.

### Check Transfer Status

```ruby
status = client.transfer_status("transfer-id")
puts "State: #{status.state}"
puts "Transaction Hash: #{status.txn_hash}" if status.txn_hash
```

## Error Handling

The SDK provides detailed error classes for different types of errors:

```ruby
begin
  client.submit_transfer(request)
rescue GasfreeSdk::InsufficientBalanceError => e
  puts "Insufficient balance: #{e.message}"
rescue GasfreeSdk::DeadlineExceededError => e
  puts "Deadline exceeded: #{e.message}"
rescue GasfreeSdk::APIError => e
  puts "API error (#{e.code}): #{e.message}"
end
```

## Troubleshooting

### Common Issues

**1. "Invalid TRON address prefix" Error**
- **Problem**: Using Ethereum address format (`0x...`) with TRON endpoints
- **Solution**: Use TRON address format (`T...`) when working with TRON networks
- **Example**: Replace `0x1234...` with `TN3W4H6rK2ce4vX9YnFQHwKENnHjoxb3m9`

**2. Data Type Validation Errors**
- **Problem**: API response data types don't match model expectations
- **Solution**: The SDK automatically handles data type conversion between API and models
- **Note**: If you encounter validation errors, ensure you're using the latest version of the SDK

**3. Authentication Errors (401)**
- **Problem**: Invalid API credentials or signature issues
- **Solution**: Verify your API key and secret are correct and properly configured
- **Check**: Ensure the endpoint URL matches your credentials (testnet vs mainnet)

### Debugging

Enable detailed logging to see API requests and responses:

```ruby
GasfreeSdk.configure do |config|
  config.logger.level = Logger::DEBUG
end
```

### Examples

Check the `examples/` directory for complete working examples:
- `examples/basic_usage.rb` - Demonstrates all main SDK features
- `examples/demo.rb` - Shows model creation and usage patterns

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/madmatvey/gasfree_sdk.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
