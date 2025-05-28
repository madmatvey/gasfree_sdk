# GasfreeSdk

Ruby SDK for interacting with the GasFree.io API, enabling gasless transfers of TRC-20/ERC-20 tokens.

## Features

- Supports gasless transfers of TRC-20/ERC-20 tokens
- Handles address generation and transaction signing
- Provides a clean, Ruby-like interface to the GasFree API
- Built with dry-rb for robust type checking and validation
- Comprehensive RSpec test coverage
- Thread-safe configuration

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

```ruby
providers = client.providers
providers.each do |provider|
  puts "Provider: #{provider.name}"
  puts "Address: #{provider.address}"
  puts "Max Pending Transfers: #{provider.config.max_pending_transfer}"
end
```

### Get GasFree Account Info

```ruby
account = client.address("0x1234...")
puts "GasFree Address: #{account.gas_free_address}"
puts "Active: #{account.active}"
puts "Nonce: #{account.nonce}"

account.assets.each do |asset|
  puts "Token: #{asset.token_symbol}"
  puts "Frozen Amount: #{asset.frozen}"
end
```

### Submit GasFree Transfer

```ruby
request = GasfreeSdk::Models::TransferRequest.new(
  token: "0x1234...", # Token address
  service_provider: "0x5678...", # Provider address
  user: "0x9abc...", # User's EOA address
  receiver: "0xdef0...", # Recipient address
  value: "1000000", # Amount in smallest unit
  max_fee: "100000", # Maximum fee in smallest unit
  deadline: Time.now.to_i + 180, # 3 minutes from now
  version: 1,
  nonce: 0,
  sig: "0x..." # User's signature
)

response = client.submit_transfer(request)
puts "Transfer ID: #{response.id}"
puts "State: #{response.state}"
```

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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/madmatvey/gasfree_sdk.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
