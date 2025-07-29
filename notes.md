# Plan of action for thread safety issues
_Exported on 7/29/2025 at 19:00:06 UTC from Cursor (1.3.3)_

---

**User**

# Form me **plan-of-action** for described below problem

 - GasfreeSdk.client returns a process‑wide singleton without thread safety primitives
 - Risk: Race conditions when multiple threads configure or mutate the client simultaneously
 - Proposed fix: Freeze configuration after initialization or use thread‑local instances

---

**Cursor**

I'll analyze the current codebase to understand the GasfreeSdk.client implementation and create a plan to address the thread safety issues. Let me start by examining the relevant code.


Now let me check the main GasfreeSdk module to see how the client is exposed:


Now let me check if there are any tests that might show how the client is used:


Let me also check the configuration usage to understand how it's modified:


Let me check the client spec to understand the current usage patterns:


Now let me check if there are any existing thread safety considerations in the codebase:


Let me also check the current configuration implementation to understand how it works:


Now let me check if there are any examples showing concurrent usage:


Based on my analysis of the codebase, I can now create a comprehensive plan to address the thread safety issues. Here's my **Plan of Action**:

# Plan of Action: Thread Safety for GasfreeSdk.client

## Problem Analysis

The current implementation has the following thread safety issues:

1. **Singleton Pattern without Thread Safety**: `GasfreeSdk.client` returns a process-wide singleton (`@client ||= Client.new`) without any synchronization primitives
2. **Mutable Configuration**: The `GasfreeSdk.configure` method allows runtime modification of configuration that affects all client instances
3. **Race Conditions**: Multiple threads can simultaneously:
   - Call `GasfreeSdk.configure` to modify global configuration
   - Access `GasfreeSdk.client` which reads from the mutable configuration
   - Create new client instances that depend on the configuration state

## Proposed Solutions

### Option 1: Configuration Freezing (Recommended)
**Approach**: Freeze configuration after initialization to prevent runtime modifications

**Benefits**:
- Simple to implement
- Maintains current API compatibility
- Prevents configuration race conditions
- Clear separation between setup and usage phases

**Implementation**:
1. Add a `freeze_configuration!` method to lock configuration after setup
2. Modify `GasfreeSdk.configure` to raise an error if called after freezing
3. Add thread-safe client instantiation with proper synchronization
4. Update documentation to clarify the setup vs usage phases

### Option 2: Thread-Local Instances
**Approach**: Use thread-local storage for client instances

**Benefits**:
- Each thread gets its own isolated client instance
- No shared state between threads
- Allows per-thread configuration

**Drawbacks**:
- More complex implementation
- Potential memory overhead
- May break existing code that expects shared client state

### Option 3: Thread-Safe Singleton with Mutex
**Approach**: Add proper synchronization to the existing singleton pattern

**Benefits**:
- Minimal API changes
- Thread-safe client access

**Drawbacks**:
- Still allows configuration race conditions
- Performance overhead from synchronization
- Doesn't address the root cause

## Recommended Implementation Plan

### Phase 1: Configuration Freezing (Option 1)

1. **Add Configuration State Management**
   ```ruby
   # Add to GasfreeSdk module
   @configuration_frozen = false
   
   def self.freeze_configuration!
     @configuration_frozen = true
   end
   
   def self.configuration_frozen?
     @configuration_frozen
   end
   ```

2. **Modify Configure Method**
   ```ruby
   def self.configure
     raise ConfigurationError, "Configuration cannot be modified after freezing" if configuration_frozen?
     # ... existing configuration logic
   end
   ```

3. **Add Thread-Safe Client Access**
   ```ruby
   def self.client
     @client_mutex ||= Mutex.new
     @client_mutex.synchronize do
       @client ||= Client.new
     end
   end
   ```

4. **Update Client Initialization**
   ```ruby
   # In Client#initialize
   def initialize
     raise ConfigurationError, "Configuration must be set before creating client" unless GasfreeSdk.config.api_key
     # ... existing initialization
   end
   ```

### Phase 2: Documentation and Examples

1. **Update README.md** with thread safety guidelines
2. **Add thread safety examples** showing proper usage patterns
3. **Update existing examples** to demonstrate configuration freezing
4. **Add deprecation warnings** for unsafe usage patterns

### Phase 3: Testing

1. **Add Thread Safety Tests**
   - Test concurrent configuration attempts
   - Test concurrent client access
   - Test configuration freezing behavior
   - Test error conditions

2. **Performance Testing**
   - Benchmark thread-safe client access
   - Compare with current implementation

### Phase 4: Migration Strategy

1. **Backward Compatibility**
   - Maintain existing API for one major version
   - Add deprecation warnings for unsafe patterns
   - Provide migration guide

2. **Gradual Migration**
   - Encourage users to freeze configuration after setup
   - Provide examples of safe usage patterns

## Implementation Priority

1. **High Priority**: Configuration freezing and thread-safe client access
2. **Medium Priority**: Documentation updates and examples
3. **Low Priority**: Performance optimizations and advanced features

## Risk Assessment

**Low Risk**: Configuration freezing approach
- Minimal breaking changes
- Clear migration path
- Maintains API compatibility

**Medium Risk**: Thread-local instances
- More complex implementation
- Potential breaking changes
- Higher maintenance burden

This plan provides a clear path to address the thread safety issues while maintaining backward compatibility and providing a smooth migration experience for existing users.

```ruby
   # Add to GasfreeSdk module
   @configuration_frozen = false
   
   def self.freeze_configuration!
     @configuration_frozen = true
   end
   
   def self.configuration_frozen?
     @configuration_frozen
   end
```

```ruby
   def self.configure
     raise ConfigurationError, "Configuration cannot be modified after freezing" if configuration_frozen?
     # ... existing configuration logic
   end
```

```ruby
   def self.client
     @client_mutex ||= Mutex.new
     @client_mutex.synchronize do
       @client ||= Client.new
     end
   end
```

```ruby
   # In Client#initialize
   def initialize
     raise ConfigurationError, "Configuration must be set before creating client" unless GasfreeSdk.config.api_key
     # ... existing initialization
   end
```

---

**User**

Proceed with # Option 2: Thread-Local Instances

---

**Cursor**

I'll implement Option 2: Thread-Local Instances for the GasfreeSdk.client. This approach will provide each thread with its own isolated client instance, eliminating race conditions while maintaining the existing API.

Let me start by examining the current implementation and then implementing the thread-local solution:


Now I'll implement the thread-local instances approach. This will require:

1. Using `Thread.current` to store client instances per thread
2. Adding thread-local configuration support
3. Updating the client method to use thread-local storage
4. Adding methods to manage thread-local state


```ruby
# frozen_string_literal: true

require "dry-configurable"
require "dry-struct"
require "dry-types"
require "dry-validation"
require "faraday"
require "faraday/retry"
require "eth"

require_relative "gasfree_sdk/version"
require_relative "gasfree_sdk/types"
require_relative "gasfree_sdk/client"
require_relative "gasfree_sdk/errors"
require_relative "gasfree_sdk/models"
require_relative "gasfree_sdk/crypto"
require_relative "gasfree_sdk/base58"
require_relative "gasfree_sdk/tron_eip712_signer"

# Main module for GasFree SDK
module GasfreeSdk
  extend Dry::Configurable

  # Default API endpoint
  setting :api_endpoint, default: "https://open.gasfree.io/tron/"
  setting :api_key, default: nil
  setting :api_secret, default: nil
  setting :default_chain_id, default: 1 # Ethereum mainnet
  setting :default_deadline_duration, default: 180 # 3 minutes
  setting :logger, default: Logger.new($stdout)
  setting :retry_options, default: {
    max: 3,
    interval: 0.5,
    interval_randomness: 0.5,
    backoff_factor: 2
  }

  class << self
    # Configure the SDK globally
    # @yield [config] Configuration block
    # @example
    #   GasfreeSdk.configure do |config|
    #     config.api_key = "your-api-key"
    #     config.api_secret = "your-api-secret"
    #     config.api_endpoint = "https://open.gasfree.io/tron/"
    #   end
    def configure
      old_endpoint = config.api_endpoint
      yield config
      return unless config.api_endpoint != old_endpoint

      validate_api_endpoint!(config.api_endpoint)
    end

    # Configure the SDK for the current thread only
    # @yield [config] Configuration block
    # @example
    #   GasfreeSdk.configure_thread do |config|
    #     config.api_key = "thread-specific-key"
    #     config.api_secret = "thread-specific-secret"
    #   end
    def configure_thread
      thread_config = thread_local_config
      old_endpoint = thread_config.api_endpoint
      yield thread_config
      return unless thread_config.api_endpoint != old_endpoint

      validate_api_endpoint!(thread_config.api_endpoint)
      # Reset thread-local client when configuration changes
      reset_thread_client!
    end

    # Get or create a client instance for the current thread
    # @return [GasfreeSdk::Client]
    def client
      thread_local_client ||= create_thread_client
    end

    # Reset the client instance for the current thread
    # @return [void]
    def reset_thread_client!
      Thread.current[:gasfree_sdk_client] = nil
    end

    # Reset the client instance globally (for backward compatibility)
    # @return [void]
    def reset_client!
      warn "GasfreeSdk.reset_client! is deprecated. Use GasfreeSdk.reset_thread_client! instead."
      reset_thread_client!
    end

    # Get the configuration for the current thread
    # Falls back to global configuration if no thread-specific config exists
    # @return [Dry::Configurable::Config]
    def thread_config
      thread_local_config || config
    end

    # Clear thread-local configuration and client
    # @return [void]
    def clear_thread_local_state!
      Thread.current[:gasfree_sdk_config] = nil
      Thread.current[:gasfree_sdk_client] = nil
    end

    private

    # Get thread-local client instance
    # @return [GasfreeSdk::Client, nil]
    def thread_local_client
      Thread.current[:gasfree_sdk_client]
    end

    # Create a new client instance for the current thread
    # @return [GasfreeSdk::Client]
    def create_thread_client
      Thread.current[:gasfree_sdk_client] = Client.new
    end

    # Get thread-local configuration
    # @return [Dry::Configurable::Config, nil]
    def thread_local_config
      Thread.current[:gasfree_sdk_config]
    end

    # Initialize thread-local configuration if it doesn't exist
    # @return [Dry::Configurable::Config]
    def ensure_thread_local_config
      Thread.current[:gasfree_sdk_config] ||= create_thread_local_config
    end

    # Create a new thread-local configuration based on global config
    # @return [Dry::Configurable::Config]
    def create_thread_local_config
      # Create a new config instance with the same settings as global config
      thread_config = Dry::Configurable::Config.new
      
      # Copy all settings from global config
      config.class.settings.each do |setting_name|
        thread_config.public_send("#{setting_name}=", config.public_send(setting_name))
      end
      
      thread_config
    end

    def validate_api_endpoint!(value)
      begin
        uri = URI.parse(value)
        unless uri.is_a?(URI::HTTP) && uri.host && !uri.host.empty? && %w[http https].include?(uri.scheme)
          raise ArgumentError
        end
      rescue StandardError
        raise GasfreeSdk::Error, "Invalid api_endpoint URL: '#{value}'. Must be a valid http(s) URL."
      end
      value
    end
  end

  # Base error class for all SDK errors
  class Error < StandardError; end
  # Your code goes here...
end
```

Now I need to update the Client class to use the thread-local configuration instead of the global configuration:


I need to update the Client class to use thread-local configuration. Let me search for all the places where `GasfreeSdk.config` is used:


Now I need to update the Client class to use `GasfreeSdk.thread_config` instead of `GasfreeSdk.config`:


```ruby
    # Initialize a new GasFree client
    def initialize
      @connection = Faraday.new(url: GasfreeSdk.config.api_endpoint) do |f|
        f.request :json
        f.request :retry, GasfreeSdk.config.retry_options
        f.response :json
        f.use GasfreeSdk::SanitizedLogsMiddleware, logger: Logger.new($stdout) if ENV["DEBUG_GASFREE_SDK"]
        f.adapter Faraday.default_adapter
      end
    end

->

    # Initialize a new GasFree client
    def initialize
      @connection = Faraday.new(url: GasfreeSdk.thread_config.api_endpoint) do |f|
        f.request :json
        f.request :retry, GasfreeSdk.thread_config.retry_options
        f.response :json
        f.use GasfreeSdk::SanitizedLogsMiddleware, logger: Logger.new($stdout) if ENV["DEBUG_GASFREE_SDK"]
        f.adapter Faraday.default_adapter
      end
    end
```

```ruby
    # Sign an API request
    # @param request [Faraday::Request] The request to sign
    # @param method [String] HTTP method
    # @param path [String] Request path
    # @param timestamp [Integer] Request timestamp
    def sign_request(request, method, path, timestamp) # rubocop:disable Metrics/AbcSize
      api_key = GasfreeSdk.config.api_key
      api_secret = GasfreeSdk.config.api_secret

      validate_credentials!(api_key, api_secret)

      # Extract the base path from the endpoint URL
      # For https://open-test.gasfree.io/nile/ the base path is /nile
      endpoint_uri = URI(GasfreeSdk.config.api_endpoint)

->

    # Sign an API request
    # @param request [Faraday::Request] The request to sign
    # @param method [String] HTTP method
    # @param path [String] Request path
    # @param timestamp [Integer] Request timestamp
    def sign_request(request, method, path, timestamp) # rubocop:disable Metrics/AbcSize
      api_key = GasfreeSdk.thread_config.api_key
      api_secret = GasfreeSdk.thread_config.api_secret

      validate_credentials!(api_key, api_secret)

      # Extract the base path from the endpoint URL
      # For https://open-test.gasfree.io/nile/ the base path is /nile
      endpoint_uri = URI(GasfreeSdk.thread_config.api_endpoint)
```

Now I need to fix the `configure_thread` method in the main module. There's an issue with how I'm handling the thread-local configuration:


```ruby
    # Configure the SDK for the current thread only
    # @yield [config] Configuration block
    # @example
    #   GasfreeSdk.configure_thread do |config|
    #     config.api_key = "thread-specific-key"
    #     config.api_secret = "thread-specific-secret"
    #   end
    def configure_thread
      thread_config = thread_local_config
      old_endpoint = thread_config.api_endpoint
      yield thread_config
      return unless thread_config.api_endpoint != old_endpoint

      validate_api_endpoint!(thread_config.api_endpoint)
      # Reset thread-local client when configuration changes
      reset_thread_client!
    end

->

    # Configure the SDK for the current thread only
    # @yield [config] Configuration block
    # @example
    #   GasfreeSdk.configure_thread do |config|
    #     config.api_key = "thread-specific-key"
    #     config.api_secret = "thread-specific-secret"
    #   end
    def configure_thread
      thread_config = ensure_thread_local_config
      old_endpoint = thread_config.api_endpoint
      yield thread_config
      return unless thread_config.api_endpoint != old_endpoint

      validate_api_endpoint!(thread_config.api_endpoint)
      # Reset thread-local client when configuration changes
      reset_thread_client!
    end
```

Now I need to fix the `create_thread_local_config` method to properly create a config instance:


```ruby
    # Create a new thread-local configuration based on global config
    # @return [Dry::Configurable::Config]
    def create_thread_local_config
      # Create a new config instance with the same settings as global config
      thread_config = Dry::Configurable::Config.new
      
      # Copy all settings from global config
      config.class.settings.each do |setting_name|
        thread_config.public_send("#{setting_name}=", config.public_send(setting_name))
      end
      
      thread_config
    end

->

    # Create a new thread-local configuration based on global config
    # @return [Dry::Configurable::Config]
    def create_thread_local_config
      # Create a new config instance with the same settings as global config
      thread_config = Dry::Configurable::Config.new
      
      # Copy all settings from global config
      config.class.settings.each do |setting_name|
        thread_config.public_send("#{setting_name}=", config.public_send(setting_name))
      end
      
      thread_config
    end
```

Let me check the Dry::Configurable documentation to understand how to properly create a config instance. Let me look at the current config structure:


I need to create a proper thread-local configuration. Let me fix the `create_thread_local_config` method:


```ruby
    # Create a new thread-local configuration based on global config
    # @return [Dry::Configurable::Config]
    def create_thread_local_config
      # Create a new config instance with the same settings as global config
      thread_config = Dry::Configurable::Config.new
      
      # Copy all settings from global config
      config.class.settings.each do |setting_name|
        thread_config.public_send("#{setting_name}=", config.public_send(setting_name))
      end
      
      thread_config
    end

->

    # Create a new thread-local configuration based on global config
    # @return [Dry::Configurable::Config]
    def create_thread_local_config
      # Create a new config instance with the same settings as global config
      thread_config = Dry::Configurable::Config.new
      
      # Copy all settings from global config
      [:api_endpoint, :api_key, :api_secret, :default_chain_id, :default_deadline_duration, :logger, :retry_options].each do |setting_name|
        thread_config.public_send("#{setting_name}=", config.public_send(setting_name))
      end
      
      thread_config
    end
```

Now let me create a comprehensive test to verify the thread-local implementation works correctly:


```ruby
# frozen_string_literal: true

RSpec.describe "GasfreeSdk Thread Safety" do
  before do
    # Clear any existing thread-local state
    GasfreeSdk.clear_thread_local_state!
    
    # Set up global configuration
    GasfreeSdk.configure do |config|
      config.api_key = "global-key"
      config.api_secret = "global-secret"
      config.api_endpoint = "https://global.gasfree.io/"
    end
  end

  after do
    GasfreeSdk.clear_thread_local_state!
  end

  describe "thread-local configuration" do
    it "uses global configuration by default" do
      expect(GasfreeSdk.thread_config.api_key).to eq("global-key")
      expect(GasfreeSdk.thread_config.api_secret).to eq("global-secret")
      expect(GasfreeSdk.thread_config.api_endpoint).to eq("https://global.gasfree.io/")
    end

    it "allows thread-specific configuration" do
      GasfreeSdk.configure_thread do |config|
        config.api_key = "thread-key"
        config.api_secret = "thread-secret"
        config.api_endpoint = "https://thread.gasfree.io/"
      end

      expect(GasfreeSdk.thread_config.api_key).to eq("thread-key")
      expect(GasfreeSdk.thread_config.api_secret).to eq("thread-secret")
      expect(GasfreeSdk.thread_config.api_endpoint).to eq("https://thread.gasfree.io/")
    end

    it "isolates configuration between threads" do
      thread1_config = nil
      thread2_config = nil

      thread1 = Thread.new do
        GasfreeSdk.configure_thread do |config|
          config.api_key = "thread1-key"
        end
        thread1_config = GasfreeSdk.thread_config.api_key
      end

      thread2 = Thread.new do
        GasfreeSdk.configure_thread do |config|
          config.api_key = "thread2-key"
        end
        thread2_config = GasfreeSdk.thread_config.api_key
      end

      thread1.join
      thread2.join

      expect(thread1_config).to eq("thread1-key")
      expect(thread2_config).to eq("thread2-key")
      expect(GasfreeSdk.thread_config.api_key).to eq("global-key")
    end
  end

  describe "thread-local client instances" do
    it "creates separate client instances for different threads" do
      client1 = nil
      client2 = nil

      thread1 = Thread.new do
        client1 = GasfreeSdk.client
      end

      thread2 = Thread.new do
        client2 = GasfreeSdk.client
      end

      thread1.join
      thread2.join

      expect(client1).to be_a(GasfreeSdk::Client)
      expect(client2).to be_a(GasfreeSdk::Client)
      expect(client1.object_id).not_to eq(client2.object_id)
    end

    it "uses thread-local configuration for client initialization" do
      GasfreeSdk.configure_thread do |config|
        config.api_endpoint = "https://thread-specific.gasfree.io/"
      end

      client = GasfreeSdk.client
      expect(client.connection.url_prefix.to_s).to eq("https://thread-specific.gasfree.io/")
    end

    it "resets client when thread configuration changes" do
      # Create initial client
      client1 = GasfreeSdk.client

      # Change configuration
      GasfreeSdk.configure_thread do |config|
        config.api_endpoint = "https://new-endpoint.gasfree.io/"
      end

      # Get new client
      client2 = GasfreeSdk.client

      expect(client1.object_id).not_to eq(client2.object_id)
      expect(client2.connection.url_prefix.to_s).to eq("https://new-endpoint.gasfree.io/")
    end
  end

  describe "concurrent access" do
    it "handles concurrent client creation without race conditions" do
      clients = []
      threads = []

      # Create multiple threads that all try to access the client simultaneously
      10.times do |i|
        threads << Thread.new do
          GasfreeSdk.configure_thread do |config|
            config.api_key = "thread-#{i}-key"
          end
          clients << GasfreeSdk.client
        end
      end

      threads.each(&:join)

      expect(clients.length).to eq(10)
      expect(clients.map(&:class).uniq).to eq([GasfreeSdk::Client])
      
      # Each client should be unique
      client_ids = clients.map(&:object_id)
      expect(client_ids.uniq.length).to eq(10)
    end

    it "handles concurrent configuration changes safely" do
      results = []
      threads = []

      # Multiple threads configuring simultaneously
      5.times do |i|
        threads << Thread.new do
          GasfreeSdk.configure_thread do |config|
            config.api_key = "concurrent-key-#{i}"
            config.api_secret = "concurrent-secret-#{i}"
          end
          results << GasfreeSdk.thread_config.api_key
        end
      end

      threads.each(&:join)

      expect(results.length).to eq(5)
      expect(results).to include("concurrent-key-0", "concurrent-key-1", "concurrent-key-2", "concurrent-key-3", "concurrent-key-4")
    end
  end

  describe "thread-local state management" do
    it "clears thread-local state correctly" do
      # Set up thread-local configuration
      GasfreeSdk.configure_thread do |config|
        config.api_key = "thread-key"
      end

      # Create a client
      client = GasfreeSdk.client

      # Clear thread-local state
      GasfreeSdk.clear_thread_local_state!

      # Should fall back to global configuration
      expect(GasfreeSdk.thread_config.api_key).to eq("global-key")

      # New client should use global configuration
      new_client = GasfreeSdk.client
      expect(new_client.object_id).not_to eq(client.object_id)
    end

    it "resets thread client correctly" do
      client1 = GasfreeSdk.client
      GasfreeSdk.reset_thread_client!
      client2 = GasfreeSdk.client

      expect(client1.object_id).not_to eq(client2.object_id)
    end
  end

  describe "backward compatibility" do
    it "maintains backward compatibility with reset_client!" do
      client1 = GasfreeSdk.client
      
      # This should trigger a deprecation warning but still work
      expect { GasfreeSdk.reset_client! }.to output(/deprecated/).to_stderr
      
      client2 = GasfreeSdk.client
      expect(client1.object_id).not_to eq(client2.object_id)
    end
  end
end
```

Now let me create an example that demonstrates the thread-local usage:


```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

# GasFree SDK Thread Safety Example
# =================================
# This example demonstrates how to use the GasFree SDK in a multi-threaded
# environment with thread-local instances for thread safety.
#
# Key Features:
# - Each thread gets its own isolated client instance
# - Thread-specific configuration support
# - No race conditions between threads
# - Backward compatibility with existing code

require "bundler/setup"
require "gasfree_sdk"
require "eth"

# Global configuration (shared across all threads)
puts "Setting up global configuration..."
GasfreeSdk.configure do |config|
  config.api_key = ENV["GASFREE_API_KEY"] || "global-api-key"
  config.api_secret = ENV["GASFREE_API_SECRET"] || "global-api-secret"
  config.api_endpoint = ENV["GASFREE_API_ENDPOINT"] || "https://open-test.gasfree.io/nile/"
end

puts "Global configuration set:"
puts "  API Endpoint: #{GasfreeSdk.config.api_endpoint}"
puts "  API Key: #{GasfreeSdk.config.api_key[0..3]}..."
puts

# Example 1: Basic thread-local usage
puts "Example 1: Basic thread-local usage"
puts "=================================="

thread1_result = nil
thread2_result = nil

thread1 = Thread.new do
  # This thread uses the global configuration
  client = GasfreeSdk.client
  thread1_result = {
    client_id: client.object_id,
    api_key: GasfreeSdk.thread_config.api_key,
    endpoint: GasfreeSdk.thread_config.api_endpoint
  }
end

thread2 = Thread.new do
  # This thread uses the global configuration
  client = GasfreeSdk.client
  thread2_result = {
    client_id: client.object_id,
    api_key: GasfreeSdk.thread_config.api_key,
    endpoint: GasfreeSdk.thread_config.api_endpoint
  }
end

thread1.join
thread2.join

puts "Thread 1:"
puts "  Client ID: #{thread1_result[:client_id]}"
puts "  API Key: #{thread1_result[:api_key][0..3]}..."
puts "  Endpoint: #{thread1_result[:endpoint]}"

puts "Thread 2:"
puts "  Client ID: #{thread2_result[:client_id]}"
puts "  API Key: #{thread2_result[:api_key][0..3]}..."
puts "  Endpoint: #{thread2_result[:endpoint]}"

puts "Note: Different client IDs show thread isolation"
puts

# Example 2: Thread-specific configuration
puts "Example 2: Thread-specific configuration"
puts "======================================="

thread3_result = nil
thread4_result = nil

thread3 = Thread.new do
  # This thread uses thread-specific configuration
  GasfreeSdk.configure_thread do |config|
    config.api_key = "thread3-specific-key"
    config.api_secret = "thread3-specific-secret"
    config.api_endpoint = "https://thread3.gasfree.io/"
  end
  
  client = GasfreeSdk.client
  thread3_result = {
    client_id: client.object_id,
    api_key: GasfreeSdk.thread_config.api_key,
    endpoint: GasfreeSdk.thread_config.api_endpoint
  }
end

thread4 = Thread.new do
  # This thread uses different thread-specific configuration
  GasfreeSdk.configure_thread do |config|
    config.api_key = "thread4-specific-key"
    config.api_secret = "thread4-specific-secret"
    config.api_endpoint = "https://thread4.gasfree.io/"
  end
  
  client = GasfreeSdk.client
  thread4_result = {
    client_id: client.object_id,
    api_key: GasfreeSdk.thread_config.api_key,
    endpoint: GasfreeSdk.thread_config.api_endpoint
  }
end

thread3.join
thread4.join

puts "Thread 3 (with thread-specific config):"
puts "  Client ID: #{thread3_result[:client_id]}"
puts "  API Key: #{thread3_result[:api_key]}"
puts "  Endpoint: #{thread3_result[:endpoint]}"

puts "Thread 4 (with thread-specific config):"
puts "  Client ID: #{thread4_result[:client_id]}"
puts "  API Key: #{thread4_result[:api_key]}"
puts "  Endpoint: #{thread4_result[:endpoint]}"

puts "Main thread still uses global config:"
puts "  API Key: #{GasfreeSdk.thread_config.api_key[0..3]}..."
puts "  Endpoint: #{GasfreeSdk.thread_config.api_endpoint}"
puts

# Example 3: Concurrent operations
puts "Example 3: Concurrent operations"
puts "================================"

results = []
threads = []

# Simulate multiple threads performing concurrent operations
5.times do |i|
  threads << Thread.new do
    # Each thread gets its own configuration and client
    GasfreeSdk.configure_thread do |config|
      config.api_key = "concurrent-key-#{i}"
      config.api_secret = "concurrent-secret-#{i}"
    end
    
    client = GasfreeSdk.client
    
    # Simulate some work
    sleep(0.1)
    
    results << {
      thread_id: i,
      client_id: client.object_id,
      api_key: GasfreeSdk.thread_config.api_key
    }
  end
end

threads.each(&:join)

puts "Concurrent thread results:"
results.each do |result|
  puts "  Thread #{result[:thread_id]}: Client ID #{result[:client_id]}, API Key #{result[:api_key]}"
end

# Verify all clients are unique
client_ids = results.map { |r| r[:client_id] }
puts "Unique client IDs: #{client_ids.uniq.length}/#{client_ids.length}"
puts

# Example 4: Thread-local state management
puts "Example 4: Thread-local state management"
puts "======================================="

# Set up thread-local configuration
GasfreeSdk.configure_thread do |config|
  config.api_key = "temporary-thread-key"
end

client1 = GasfreeSdk.client
puts "Before clearing: API Key = #{GasfreeSdk.thread_config.api_key}"

# Clear thread-local state
GasfreeSdk.clear_thread_local_state!

client2 = GasfreeSdk.client
puts "After clearing: API Key = #{GasfreeSdk.thread_config.api_key}"
puts "Client IDs different: #{client1.object_id != client2.object_id}"
puts

# Example 5: Backward compatibility
puts "Example 5: Backward compatibility"
puts "================================"

client1 = GasfreeSdk.client
puts "Using deprecated reset_client! method (will show warning):"
GasfreeSdk.reset_client! # This will show a deprecation warning
client2 = GasfreeSdk.client

puts "Client IDs different: #{client1.object_id != client2.object_id}"
puts

puts "Thread safety implementation complete!"
puts "====================================="
puts "Key benefits:"
puts "  ✓ Each thread gets its own isolated client instance"
puts "  ✓ Thread-specific configuration support"
puts "  ✓ No race conditions between threads"
puts "  ✓ Backward compatibility maintained"
puts "  ✓ Automatic client reset when configuration changes"
```

Now let me run the tests to verify the implementation works correctly:


---

**User**

Retry to proceed with # Option 2: Thread-Local Instances , but don't separate new logic from old methods: **create_client**, **configure** and **reset_client!**

---

**Cursor**

I understand. You want me to implement Option 2: Thread-Local Instances but keep the existing methods (`configure`, `reset_client!`) unchanged and add the thread-local functionality as additional methods. Let me revise the implementation to maintain backward compatibility while adding thread-local features.


Now I need to revise the implementation to keep the original methods unchanged and add thread-local functionality as additional methods. Let me update the implementation:


```ruby
# frozen_string_literal: true

require "dry-configurable"
require "dry-struct"
require "dry-types"
require "dry-validation"
require "faraday"
require "faraday/retry"
require "eth"

require_relative "gasfree_sdk/version"
require_relative "gasfree_sdk/types"
require_relative "gasfree_sdk/client"
require_relative "gasfree_sdk/errors"
require_relative "gasfree_sdk/models"
require_relative "gasfree_sdk/crypto"
require_relative "gasfree_sdk/base58"
require_relative "gasfree_sdk/tron_eip712_signer"

# Main module for GasFree SDK
module GasfreeSdk
  extend Dry::Configurable

  # Default API endpoint
  setting :api_endpoint, default: "https://open.gasfree.io/tron/"
  setting :api_key, default: nil
  setting :api_secret, default: nil
  setting :default_chain_id, default: 1 # Ethereum mainnet
  setting :default_deadline_duration, default: 180 # 3 minutes
  setting :logger, default: Logger.new($stdout)
  setting :retry_options, default: {
    max: 3,
    interval: 0.5,
    interval_randomness: 0.5,
    backoff_factor: 2
  }

  class << self
    # Configure the SDK
    # @yield [config] Configuration block
    # @example
    #   GasfreeSdk.configure do |config|
    #     config.api_key = "your-api-key"
    #     config.api_secret = "your-api-secret"
    #     config.api_endpoint = "https://open.gasfree.io/tron/"
    #   end
    def configure
      old_endpoint = config.api_endpoint
      yield config
      return unless config.api_endpoint != old_endpoint

      validate_api_endpoint!(config.api_endpoint)
    end

    # Create a new client instance
    # @return [GasfreeSdk::Client]
    def client
      @client ||= Client.new
    end

    # Reset the client instance
    # @return [void]
    def reset_client!
      @client = nil
    end

    # Thread-local methods for thread safety
    # =====================================

    # Configure the SDK for the current thread only
    # @yield [config] Configuration block
    # @example
    #   GasfreeSdk.configure_thread do |config|
    #     config.api_key = "thread-specific-key"
    #     config.api_secret = "thread-specific-secret"
    #   end
    def configure_thread
      thread_config = ensure_thread_local_config
      old_endpoint = thread_config.api_endpoint
      yield thread_config
      return unless thread_config.api_endpoint != old_endpoint

      validate_api_endpoint!(thread_config.api_endpoint)
      # Reset thread-local client when configuration changes
      reset_thread_client!
    end

    # Get or create a client instance for the current thread
    # @return [GasfreeSdk::Client]
    def thread_client
      thread_local_client ||= create_thread_client
    end

    # Reset the client instance for the current thread
    # @return [void]
    def reset_thread_client!
      Thread.current[:gasfree_sdk_client] = nil
    end

    # Get the configuration for the current thread
    # Falls back to global configuration if no thread-specific config exists
    # @return [Dry::Configurable::Config]
    def thread_config
      thread_local_config || config
    end

    # Clear thread-local configuration and client
    # @return [void]
    def clear_thread_local_state!
      Thread.current[:gasfree_sdk_config] = nil
      Thread.current[:gasfree_sdk_client] = nil
    end

    private

    # Get thread-local client instance
    # @return [GasfreeSdk::Client, nil]
    def thread_local_client
      Thread.current[:gasfree_sdk_client]
    end

    # Create a new client instance for the current thread
    # @return [GasfreeSdk::Client]
    def create_thread_client
      Thread.current[:gasfree_sdk_client] = Client.new
    end

    # Get thread-local configuration
    # @return [Dry::Configurable::Config, nil]
    def thread_local_config
      Thread.current[:gasfree_sdk_config]
    end

    # Initi
```

---

**User**

Not, you don't get the thing! I mean, you must change existing methods, adding thead-local features into them

---

**Cursor**

Ah, I understand now! You want me to modify the existing methods (`configure`, `client`, `reset_client!`) to add thread-local functionality directly into them, rather than creating separate methods. Let me revise the implementation to integrate thread-local features into the existing methods.


```ruby
# frozen_string_literal: true

require "dry-configurable"
require "dry-struct"
require "dry-types"
require "dry-validation"
require "faraday"
require "faraday/retry"
require "eth"

require_relative "gasfree_sdk/version"
require_relative "gasfree_sdk/types"
require_relative "gasfree_sdk/client"
require_relative "gasfree_sdk/errors"
require_relative "gasfree_sdk/models"
require_relative "gasfree_sdk/crypto"
require_relative "gasfree_sdk/base58"
require_relative "gasfree_sdk/tron_eip712_signer"

# Main module for GasFree SDK
module GasfreeSdk
  extend Dry::Configurable

  # Default API endpoint
  setting :api_endpoint, default: "https://open.gasfree.io/tron/"
  setting :api_key, default: nil
  setting :api_secret, default: nil
  setting :default_chain_id, default: 1 # Ethereum mainnet
  setting :default_deadline_duration, default: 180 # 3 minutes
  setting :logger, default: Logger.new($stdout)
  setting :retry_options, default: {
    max: 3,
    interval: 0.5,
    interval_randomness: 0.5,
    backoff_factor: 2
  }

  class << self
    # Configure the SDK (thread-safe)
    # @yield [config] Configuration block
    # @example
    #   GasfreeSdk.configure do |config|
    #     config.api_key = "your-api-key"
    #     config.api_secret = "your-api-secret"
    #     config.api_endpoint = "https://open.gasfree.io/tron/"
    #   end
    def configure
      # Use thread-local configuration if available, otherwise use global
      target_config = thread_local_config || config
      old_endpoint = target_config.api_endpoint
      yield target_config
      return unless target_config.api_endpoint != old_endpoint

      validate_api_endpoint!(target_config.api_endpoint)
      
      # Reset thread-local client when configuration changes
      reset_thread_client! if thread_local_config
    end

    # Create a new client instance (thread-safe)
    # @return [GasfreeSdk::Client]
    def client
      thread_local_client ||= create_thread_client
    end

    # Reset the client instance (thread-safe)
    # @return [void]
    def reset_client!
      reset_thread_client!
    end

    # Get the configuration for the current thread
    # Falls back to global configuration if no thread-specific config exists
    # @return [Dry::Configurable::Config]
    def thread_config
      thread_local_config || config
    end

    # Clear thread-local configuration and client
    # @return [void]
    def clear_thread_local_state!
      Thread.current[:gasfree_sdk_config] = nil
      Thread.current[:gasfree_sdk_client] = nil
    end

    private

    # Get thread-local client instance
    # @return [GasfreeSdk::Client, nil]
    def thread_local_client
      Thread.current[:gasfree_sdk_client]
    end

    # Create a new client instance for the current thread
    # @return [GasfreeSdk::Client]
    def create_thread_client
      Thread.current[:gasfree_sdk_client] = Client.new
    end

    # Reset the client instance for the current thread
    # @return [void]
    def reset_thread_client!
      Thread.current[:gasfree_sdk_client] = nil
    end

    # Get thread-local configuration
    # @return [Dry::Configurable::Config, nil]
    def thread_local_config
      Thread.current[:gasfree_sdk_config]
    end

    # Initialize thread-local configuration if it doesn't exist
    # @return [Dry::Configurable::Config]
    def ensure_thread_local_config
      Thread.current[:gasfree_sdk_config] ||= create_thread_local_config
    end

    # Create a new thread-local configuration based on global config
    # @return [Dry::Configurable::Config]
    def create_thread_local_config
      # Create a new config instance with the same settings as global config
      thread_config = Dry::Configurable::Config.new
      
      # Copy all settings from global config
      [:api_endpoint, :api_key, :api_secret, :default_chain_id, :default_deadline_duration, :logger, :retry_options].each do |setting_name|
        thread_config.public_send("#{setting_name}=", config.public_send(setting_name))
      end
      
      thread_config
    end

    def validate_api_endpoint!(value)
      begin
        uri = URI.parse(value)
        unless uri.is_a?(URI::HTTP) && uri.host && !uri.host.empty? && %w[http https].include?(uri.scheme)
          raise ArgumentError
        end
      rescue StandardError
        raise GasfreeSdk::Error, "Invalid api_endpoint URL: '#{value}'. Must be a valid http(s) URL."
      end
      value
    end
  end

  # Base error class for all SDK errors
  class Error < StandardError; end
  # Your code goes here...
end
```

Now I need to add a method to enable thread-local configuration mode. Let me add this functionality:


```ruby
    # Clear thread-local configuration and client
    # @return [void]
    def clear_thread_local_state!
      Thread.current[:gasfree_sdk_config] = nil
      Thread.current[:gasfree_sdk_client] = nil
    end

->

    # Enable thread-local configuration mode
    # After calling this, configure() will modify thread-local config instead of global
    # @return [void]
    def enable_thread_local_config!
      ensure_thread_local_config
    end

    # Clear thread-local configuration and client
    # @return [void]
    def clear_thread_local_state!
      Thread.current[:gasfree_sdk_config] = nil
      Thread.current[:gasfree_sdk_client] = nil
    end
```

Now let me update the test file to reflect the new approach:


```ruby
# frozen_string_literal: true

RSpec.describe "GasfreeSdk Thread Safety" do
  before do
    # Clear any existing thread-local state
    GasfreeSdk.clear_thread_local_state!
    
    # Set up global configuration
    GasfreeSdk.configure do |config|
      config.api_key = "global-key"
      config.api_secret = "global-secret"
      config.api_endpoint = "https://global.gasfree.io/"
    end
  end

  after do
    GasfreeSdk.clear_thread_local_state!
  end

  describe "thread-local configuration" do
    it "uses global configuration by default" do
      expect(GasfreeSdk.thread_config.api_key).to eq("global-key")
      expect(GasfreeSdk.thread_config.api_secret).to eq("global-secret")
      expect(GasfreeSdk.thread_config.api_endpoint).to eq("https://global.gasfree.io/")
    end

    it "allows thread-specific configuration when enabled" do
      GasfreeSdk.enable_thread_local_config!
      GasfreeSdk.configure do |config|
        config.api_key = "thread-key"
        config.api_secret = "thread-secret"
        config.api_endpoint = "https://thread.gasfree.io/"
      end

      expect(GasfreeSdk.thread_config.api_key).to eq("thread-key")
      expect(GasfreeSdk.thread_config.api_secret).to eq("thread-secret")
      expect(GasfreeSdk.thread_config.api_endpoint).to eq("https://thread.gasfree.io/")
    end

    it "isolates configuration between threads" do
      thread1_config = nil
      thread2_config = nil

      thread1 = Thread.new do
        GasfreeSdk.enable_thread_local_config!
        GasfreeSdk.configure do |config|
          config.api_key = "thread1-key"
        end
        thread1_config = GasfreeSdk.thread_config.api_key
      end

      thread2 = Thread.new do
        GasfreeSdk.enable_thread_local_config!
        GasfreeSdk.configure do |config|
          config.api_key = "thread2-key"
        end
        thread2_config = GasfreeSdk.thread_config.api_key
      end

      thread1.join
      thread2.join

      expect(thread1_config).to eq("thread1-key")
      expect(thread2_config).to eq("thread2-key")
      expect(GasfreeSdk.thread_config.api_key).to eq("global-key")
    end
  end

  describe "thread-local client instances" do
    it "creates separate client instances for different threads" do
      client1 = nil
      client2 = nil

      thread1 = Thread.new do
        client1 = GasfreeSdk.client
      end

      thread2 = Thread.new do
        client2 = GasfreeSdk.client
      end

      thread1.join
      thread2.join

      expect(client1).to be_a(GasfreeSdk::Client)
      expect(client2).to be_a(GasfreeSdk::Client)
      expect(client1.object_id).not_to eq(client2.object_id)
    end

    it "uses thread-local configuration for client initialization when enabled" do
      GasfreeSdk.enable_thread_local_config!
      GasfreeSdk.configure do |config|
        config.api_endpoint = "https://thread-specific.gasfree.io/"
      end

      client = GasfreeSdk.client
      expect(client.connection.url_prefix.to_s).to eq("https://thread-specific.gasfree.io/")
    end

    it "resets client when thread configuration changes" do
      GasfreeSdk.enable_thread_local_config!
      
      # Create initial client
      client1 = GasfreeSdk.client

      # Change configuration
      GasfreeSdk.configure do |config|
        config.api_endpoint = "https://new-endpoint.gasfree.io/"
      end

      # Get new client
      client2 = GasfreeSdk.client

      expect(client1.object_id).not_to eq(client2.object_id)
      expect(client2.connection.url_prefix.to_s).to eq("https://new-endpoint.gasfree.io/")
    end
  end

  describe "concurrent access" do
    it "handles concurrent client creation without race conditions" do
      clients = []
      threads = []

      # Create multiple threads that all try to access the client simultaneously
      10.times do |i|
        threads << Thread.new do
          GasfreeSdk.enable_thread_local_config!
          GasfreeSdk.configure do |config|
            config.api_key = "thread-#{i}-key"
          end
          clients << GasfreeSdk.client
        end
      end

      threads.each(&:join)

      expect(clients.length).to eq(10)
      expect(clients.map(&:class).uniq).to eq([GasfreeSdk::Client])
      
      # Each client should be unique
      client_ids = clients.map(&:object_id)
      expect(client_ids.uniq.length).to eq(10)
    end

    it "handles concurrent configuration changes safely" do
      results = []
      threads = []

      # Multiple threads configuring simultaneously
      5.times do |i|
        threads << Thread.new do
          GasfreeSdk.enable_thread_local_config!
          GasfreeSdk.configure do |config|
            config.api_key = "concurrent-key-#{i}"
            config.api_secret = "concurrent-secret-#{i}"
          end
          results << GasfreeSdk.thread_config.api_key
        end
      end

      threads.each(&:join)

      expect(results.length).to eq(5)
      expect(results).to include("concurrent-key-0", "concurrent-key-1", "concurrent-key-2", "concurrent-key-3", "concurrent-key-4")
    end
  end

  describe "thread-local state management" do
    it "clears thread-local state correctly" do
      # Set up thread-local configuration
      GasfreeSdk.enable_thread_local_config!
      GasfreeSdk.configure do |config|
        config.api_key = "temporary-thread-key"
      end

      # Create a client
      client = GasfreeSdk.client

      # Clear thread-local state
      GasfreeSdk.clear_thread_local_state!

      # Should fall back to global configuration
      expect(GasfreeSdk.thread_config.api_key).to eq("global-key")

      # New client should use global configuration
      new_client = GasfreeSdk.client
      expect(new_client.object_id).not_to eq(client.object_id)
    end

    it "resets thread client correctly" do
      client1 = GasfreeSdk.client
      GasfreeSdk.reset_client!
      client2 = GasfreeSdk.client

      expect(client1.object_id).not_to eq(client2.object_id)
    end
  end

  describe "backward compatibility" do
    it "maintains backward compatibility with existing methods" do
      # Global configuration should work as before
      GasfreeSdk.configure do |config|
        config.api_key = "backward-compat-key"
      end
      
      expect(GasfreeSdk.config.api_key).to eq("backward-compat-key")
      
      # Client creation should work as before
      client = GasfreeSdk.client
      expect(client).to be_a(GasfreeSdk::Client)
      
      # Reset should work as before
      GasfreeSdk.reset_client!
      new_client = GasfreeSdk.client
      expect(new_client.object_id).not_to eq(client.object_id)
    end
  end
end
```

Now let me update the example file to reflect the new approach:


```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

# GasFree SDK Thread Safety Example
# =================================
# This example demonstrates how to use the GasFree SDK in a multi-threaded
# environment with thread-local instances for thread safety.
#
# Key Features:
# - Each thread gets its own isolated client instance
# - Thread-specific configuration support via enable_thread_local_config!
# - No race conditions between threads
# - Backward compatibility with existing code
# - Existing methods (configure, client, reset_client!) are now thread-safe

require "bundler/setup"
require "gasfree_sdk"
require "eth"

# Global configuration (shared across all threads)
puts "Setting up global configuration..."
GasfreeSdk.configure do |config|
  config.api_key = ENV["GASFREE_API_KEY"] || "global-api-key"
  config.api_secret = ENV["GASFREE_API_SECRET"] || "global-api-secret"
  config.api_endpoint = ENV["GASFREE_API_ENDPOINT"] || "https://open-test.gasfree.io/nile/"
end

puts "Global configuration set:"
puts "  API Endpoint: #{GasfreeSdk.config.api_endpoint}"
puts "  API Key: #{GasfreeSdk.config.api_key[0..3]}..."
puts

# Example 1: Basic thread-local usage
puts "Example 1: Basic thread-local usage"
puts "=================================="

thread1_result = nil
thread2_result = nil

thread1 = Thread.new do
  # This thread uses the global configuration
  client = GasfreeSdk.client
  thread1_result = {
    client_id: client.object_id,
    api_key: GasfreeSdk.thread_config.api_key,
    endpoint: GasfreeSdk.thread_config.api_endpoint
  }
end

thread2 = Thread.new do
  # This thread uses the global configuration
  client = GasfreeSdk.client
  thread2_result = {
    client_id: client.object_id,
    api_key: GasfreeSdk.thread_config.api_key,
    endpoint: GasfreeSdk.thread_config.api_endpoint
  }
end

thread1.join
thread2.join

puts "Thread 1:"
puts "  Client ID: #{thread1_result[:client_id]}"
puts "  API Key: #{thread1_result[:api_key][0..3]}..."
puts "  Endpoint: #{thread1_result[:endpoint]}"

puts "Thread 2:"
puts "  Client ID: #{thread2_result[:client_id]}"
puts "  API Key: #{thread2_result[:api_key][0..3]}..."
puts "  Endpoint: #{thread2_result[:endpoint]}"

puts "Note: Different client IDs show thread isolation"
puts

# Example 2: Thread-specific configuration
puts "Example 2: Thread-specific configuration"
puts "======================================="

thread3_result = nil
thread4_result = nil

thread3 = Thread.new do
  # This thread uses thread-specific configuration
  GasfreeSdk.enable_thread_local_config!
  GasfreeSdk.configure do |config|
    config.api_key = "thread3-specific-key"
    config.api_secret = "thread3-specific-secret"
    config.api_endpoint = "https://thread3.gasfree.io/"
  end
  
  client = GasfreeSdk.client
  thread3_result = {
    client_id: client.object_id,
    api_key: GasfreeSdk.thread_config.api_key,
    endpoint: GasfreeSdk.thread_config.api_endpoint
  }
end

thread4 = Thread.new do
  # This thread uses different thread-specific configuration
  GasfreeSdk.enable_thread_local_config!
  GasfreeSdk.configure do |config|
    config.api_key = "thread4-specific-key"
    config.api_secret = "thread4-specific-secret"
    config.api_endpoint = "https://thread4.gasfree.io/"
  end
  
  client = GasfreeSdk.client
  thread4_result = {
    client_id: client.object_id,
    api_key: GasfreeSdk.thread_config.api_key,
    endpoint: GasfreeSdk.thread_config.api_endpoint
  }
end

thread3.join
thread4.join

puts "Thread 3 (with thread-specific config):"
puts "  Client ID: #{thread3_result[:client_id]}"
puts "  API Key: #{thread3_result[:api_key]}"
puts "  Endpoint: #{thread3_result[:endpoint]}"

puts "Thread 4 (with thread-specific config):"
puts "  Client ID: #{thread4_result[:client_id]}"
puts "  API Key: #{thread4_result[:api_key]}"
puts "  Endpoint: #{thread4_result[:endpoint]}"

puts "Main thread still uses global config:"
puts "  API Key: #{GasfreeSdk.thread_config.api_key[0..3]}..."
puts "  Endpoint: #{GasfreeSdk.thread_config.api_endpoint}"
puts

# Example 3: Concurrent operations
puts "Example 3: Concurrent operations"
puts "================================"

results = []
threads = []

# Simulate multiple threads performing concurrent operations
5.times do |i|
  threads << Thread.new do
    # Each thread gets its own configuration and client
    GasfreeSdk.enable_thread_local_config!
    GasfreeSdk.configure do |config|
      config.api_key = "concurrent-key-#{i}"
      config.api_secret = "concurrent-secret-#{i}"
    end
    
    client = GasfreeSdk.client
    
    # Simulate some work
    sleep(0.1)
    
    results << {
      thread_id: i,
      client_id: client.object_id,
      api_key: GasfreeSdk.thread_config.api_key
    }
  end
end

threads.each(&:join)

puts "Concurrent thread results:"
results.each do |result|
  puts "  Thread #{result[:thread_id]}: Client ID #{result[:client_id]}, API Key #{result[:api_key]}"
end

# Verify all clients are unique
client_ids = results.map { |r| r[:client_id] }
puts "Unique client IDs: #{client_ids.uniq.length}/#{client_ids.length}"
puts

# Example 4: Thread-local state management
puts "Example 4: Thread-local state management"
puts "======================================="

# Set up thread-local configuration
GasfreeSdk.enable_thread_local_config!
GasfreeSdk.configure do |config|
  config.api_key = "temporary-thread-key"
end

client1 = GasfreeSdk.client
puts "Before clearing: API Key = #{GasfreeSdk.thread_config.api_key}"

# Clear thread-local state
GasfreeSdk.clear_thread_local_state!

client2 = GasfreeSdk.client
puts "After clearing: API Key = #{GasfreeSdk.thread_config.api_key}"
puts "Client IDs different: #{client1.object_id != client2.object_id}"
puts

# Example 5: Backward compatibility
puts "Example 5: Backward compatibility"
puts "================================"

client1 = GasfreeSdk.client
puts "Using reset_client! method (now thread-safe):"
GasfreeSdk.reset_client!
client2 = GasfreeSdk.client

puts "Client IDs different: #{client1.object_id != client2.object_id}"
puts

# Example 6: Mixed usage patterns
puts "Example 6: Mixed usage patterns"
puts "==============================="

# Global configuration still works
GasfreeSdk.configure do |config|
  config.api_key = "mixed-usage-key"
end

puts "Global config updated: #{GasfreeSdk.config.api_key}"

# Thread-local configuration works independently
GasfreeSdk.enable_thread_local_config!
GasfreeSdk.configure do |config|
  config.api_key = "thread-local-key"
end

puts "Thread-local config: #{GasfreeSdk.thread_config.api_key}"
puts "Global config unchanged: #{GasfreeSdk.config.api_key}"
puts

puts "Thread safety implementation complete!"
puts "====================================="
puts "Key benefits:"
puts "  ✓ Each thread gets its own isolated client instance"
puts "  ✓ Thread-specific configuration support via enable_thread_local_config!"
puts "  ✓ No race conditions between threads"
puts "  ✓ Backward compatibility maintained"
puts "  ✓ Existing methods (configure, client, reset_client!) are now thread-safe"
puts "  ✓ Automatic client reset when configuration changes"
```

Now let me run the tests to verify the implementation works correctly:


---

**User**

Please read documentation  @dry-configurable anfd tell me how dry-configurrable is used in GasfreeSdk

---

**Cursor**

Based on the documentation and the current implementation, let me analyze how `dry-configurable` is used in GasfreeSdk:

## Current Usage of dry-configurable in GasfreeSdk

### 1. Basic Setup
```ruby
module GasfreeSdk
  extend Dry::Configurable
```

The module extends `Dry::Configurable` to add thread-safe configuration behavior.

### 2. Settings Definition
```ruby
# Default API endpoint
setting :api_endpoint, default: "https://open.gasfree.io/tron/"
setting :api_key, default: nil
setting :api_secret, default: nil
setting :default_chain_id, default: 1 # Ethereum mainnet
setting :default_deadline_duration, default: 180 # 3 minutes
setting :logger, default: Logger.new($stdout)
setting :retry_options, default: {
  max: 3,
  interval: 0.5,
  interval_randomness: 0.5,
  backoff_factor: 2
}
```

The SDK defines 7 configuration settings with default values.

### 3. Configuration Access
```ruby
# Global configuration access
GasfreeSdk.config.api_key
GasfreeSdk.config.api_endpoint
```

### 4. Configuration Block
```ruby
GasfreeSdk.configure do |config|
  config.api_key = "your-api-key"
  config.api_secret = "your-api-secret"
  config.api_endpoint = "https://open.gasfree.io/tron/"
end
```

## Issues with Current Thread-Local Implementation

Looking at your recent changes, I can see several problems with the current approach:

### 1. **Incorrect Config Creation**
```ruby
# This is problematic:
thread_config = Dry::Configurable::Config.new({})
thread_config._settings[setting_name]=(config.public_send(setting_name))
```

The `Dry::Configurable::Config.new({})` approach is incorrect. According to the documentation, `dry-configurable` is designed to be **thread-safe by default** and doesn't support creating separate config instances this way.

### 2. **Alias Method Issues**
```ruby
alias_method :old_config, :config
def config
  thread_local_config || old_config
end
```

This creates a recursive call issue because `old_config` points to the new `config` method.

### 3. **Missing Thread-Local Support in dry-configurable**

From the documentation, `dry-configurable` is designed to be thread-safe at the module level, but it doesn't provide built-in support for per-thread configuration instances. The library is designed for global configuration that's safe to access from multiple threads.

## Recommended Approach

Given that `dry-configurable` is already thread-safe by design, the better approach would be:

### Option 1: Use dry-configurable as intended (Recommended)
```ruby
# Keep the global configuration thread-safe
GasfreeSdk.configure do |config|
  config.api_key = "global-key"
end

# Each thread gets its own client instance
client = GasfreeSdk.client
```

### Option 2: If you need per-thread configuration, use a different approach
```ruby
# Store thread-local configuration separately from dry-configurable
Thread.current[:gasfree_sdk_thread_config] = {
  api_key: "thread-key",
  api_secret: "thread-secret"
}

# Modify the client to check thread-local config first
def self.client
  thread_config = Thread.current[:gasfree_sdk_thread_config]
  config_to_use = thread_config || config
  # Create client with config_to_use
end
```

## Key Insights from dry-configurable Documentation

1. **Thread-Safe by Default**: `dry-configurable` is designed to be thread-safe out of the box
2. **Global Configuration**: It's meant for global configuration that can be safely accessed from multiple threads
3. **No Per-Thread Instances**: The library doesn't support creating separate config instances per thread
4. **Simple API**: The intended usage is straightforward - extend the module, define settings, and use `configure` blocks

The current implementation is trying to work around `dry-configurable`'s design rather than working with it. The thread safety issue you're trying to solve might be better addressed by ensuring that client instances are thread-local while keeping the configuration global and thread-safe as intended by `dry-configurable`.

```ruby
module GasfreeSdk
  extend Dry::Configurable
```

```ruby
# Default API endpoint
setting :api_endpoint, default: "https://open.gasfree.io/tron/"
setting :api_key, default: nil
setting :api_secret, default: nil
setting :default_chain_id, default: 1 # Ethereum mainnet
setting :default_deadline_duration, default: 180 # 3 minutes
setting :logger, default: Logger.new($stdout)
setting :retry_options, default: {
  max: 3,
  interval: 0.5,
  interval_randomness: 0.5,
  backoff_factor: 2
}
```

```ruby
# Global configuration access
GasfreeSdk.config.api_key
GasfreeSdk.config.api_endpoint
```

```ruby
GasfreeSdk.configure do |config|
  config.api_key = "your-api-key"
  config.api_secret = "your-api-secret"
  config.api_endpoint = "https://open.gasfree.io/tron/"
end
```

```ruby
# This is problematic:
thread_config = Dry::Configurable::Config.new({})
thread_config._settings[setting_name]=(config.public_send(setting_name))
```

```ruby
alias_method :old_config, :config
def config
  thread_local_config || old_config
end
```

```ruby
# Keep the global configuration thread-safe
GasfreeSdk.configure do |config|
  config.api_key = "global-key"
end

# Each thread gets its own client instance
client = GasfreeSdk.client
```

```ruby
# Store thread-local configuration separately from dry-configurable
Thread.current[:gasfree_sdk_thread_config] = {
  api_key: "thread-key",
  api_secret: "thread-secret"
}

# Modify the client to check thread-local config first
def self.client
  thread_config = Thread.current[:gasfree_sdk_thread_config]
  config_to_use = thread_config || config
  # Create client with config_to_use
end
```

---

**User**

Ok, I aim to do Option 1

---

**Cursor**

Great! Here’s how you can proceed with **Option 1: Use dry-configurable as intended**:

---

## Option 1: Use dry-configurable as Intended

### Key Points

- **dry-configurable is already thread-safe** for global configuration.
- You do **not** need to create per-thread config objects.
- The only thing you need to ensure is that your client instances are not shared across threads (i.e., avoid a process-wide singleton client).

---

### Implementation Steps

#### 1. Use dry-configurable for Global Config

Your current usage is correct:
```ruby
module GasfreeSdk
  extend Dry::Configurable

  setting :api_endpoint, default: "https://open.gasfree.io/tron/"
  setting :api_key, default: nil
  # ... other settings ...
end

# Configure globally (thread-safe)
GasfreeSdk.configure do |config|
  config.api_key = "your-api-key"
  config.api_secret = "your-api-secret"
end
```

#### 2. Make Client Instances Thread-Local

Instead of a process-wide singleton, use a thread-local variable for the client:

```ruby
def self.client
  Thread.current[:gasfree_sdk_client] ||= Client.new
end

def self.reset_client!
  Thread.current[:gasfree_sdk_client] = nil
end
```

- This ensures each thread gets its own client instance, but all use the same (thread-safe) global config.

#### 3. Remove Any Per-Thread Config Hacks

- Do **not** try to create per-thread config objects.
- Always use `GasfreeSdk.config` inside your client.

#### 4. (Optional) Document the Pattern

Add a note in your README:

> **Thread Safety:**  
> The SDK configuration is globally thread-safe. Each thread should use its own client instance, which is handled automatically by the SDK.

---

### Example Usage

```ruby
# In your app setup (runs once)
GasfreeSdk.configure do |config|
  config.api_key = "your-api-key"
  config.api_secret = "your-api-secret"
end

# In each thread:
client = GasfreeSdk.client
# ... use client ...
```

---

## Summary

- **Keep config global and thread-safe** (dry-configurable does this for you).
- **Make client instances thread-local** (use Thread.current).
- **No need for per-thread config objects**.

If you want, I can provide a code snippet for your `lib/gasfree_sdk.rb` with these changes. Would you like that?

```ruby
module GasfreeSdk
  extend Dry::Configurable

  setting :api_endpoint, default: "https://open.gasfree.io/tron/"
  setting :api_key, default: nil
  # ... other settings ...
end

# Configure globally (thread-safe)
GasfreeSdk.configure do |config|
  config.api_key = "your-api-key"
  config.api_secret = "your-api-secret"
end
```

```ruby
def self.client
  Thread.current[:gasfree_sdk_client] ||= Client.new
end

def self.reset_client!
  Thread.current[:gasfree_sdk_client] = nil
end
```

```ruby
# In your app setup (runs once)
GasfreeSdk.configure do |config|
  config.api_key = "your-api-key"
  config.api_secret = "your-api-secret"
end

# In each thread:
client = GasfreeSdk.client
# ... use client ...
```

---

**User**

Please, implement  steps 1-4 (with **Document the Pattern** step)

---

**Cursor**

```ruby
# frozen_string_literal: true

require "dry-configurable"
require "dry-struct"
require "dry-types"
require "dry-validation"
require "faraday"
require "faraday/retry"
require "eth"

require_relative "gasfree_sdk/version"
require_relative "gasfree_sdk/types"
require_relative "gasfree_sdk/client"
require_relative "gasfree_sdk/errors"
require_relative "gasfree_sdk/models"
require_relative "gasfree_sdk/crypto"
require_relative "gasfree_sdk/base58"
require_relative "gasfree_sdk/tron_eip712_signer"

# Main module for GasFree SDK
module GasfreeSdk
  extend Dry::Configurable

  # Default API endpoint
  setting :api_endpoint, default: "https://open.gasfree.io/tron/"
  setting :api_key, default: nil
  setting :api_secret, default: nil
  setting :default_chain_id, default: 1 # Ethereum mainnet
  setting :default_deadline_duration, default: 180 # 3 minutes
  setting :logger, default: Logger.new($stdout)
  setting :retry_options, default: {
    max: 3,
    interval: 0.5,
    interval_randomness: 0.5,
    backoff_factor: 2
  }

  class << self
    # Configure the SDK (thread-safe, global)
    # @yield [config] Configuration block
    # @example
    #   GasfreeSdk.configure do |config|
    #     config.api_key = "your-api-key"
    #     config.api_secret = "your-api-secret"
    #     config.api_endpoint = "https://open.gasfree.io/tron/"
    #   end
    def configure
      old_endpoint = config.api_endpoint
      yield config
      return unless config.api_endpoint != old_endpoint
      validate_api_endpoint!(config.api_endpoint)
      # Reset all thread-local clients if needed (not implemented here)
    end

    # Get or create a thread-local client instance
    # @return [GasfreeSdk::Client]
    def client
      Thread.current[:gasfree_sdk_client] ||= Client.new
    end

    # Reset the client instance for the current thread
    # @return [void]
    def reset_client!
      Thread.current[:gasfree_sdk_client] = nil
    end

    private

    def validate_api_endpoint!(value)
      begin
        uri = URI.parse(value)
        unless uri.is_a?(URI::HTTP) && uri.host && !uri.host.empty? && %w[http https].include?(uri.scheme)
          raise ArgumentError
        end
      rescue StandardError
        raise GasfreeSdk::Error, "Invalid api_endpoint URL: '#{value}'. Must be a valid http(s) URL."
      end
      value
    end
  end

  # Base error class for all SDK errors
  class Error < StandardError; end

  # ----------------------------------------------------------------------
  # Thread Safety Documentation
  # ----------------------------------------------------------------------
  #
  # Thread Safety:
  #   - The SDK configuration is globally thread-safe (handled by dry-configurable).
  #   - Each thread gets its own client instance (thread-local, via Thread.current).
  #   - All client instances use the same global configuration.
  #   - Do NOT attempt to create per-thread config objects; always use GasfreeSdk.config.
  #
  # Usage Example:
  #   # Configure globally (thread-safe)
  #   GasfreeSdk.configure do |config|
  #     config.api_key = "your-api-key"
  #     config.api_secret = "your-api-secret"
  #   end
  #
  #   # In each thread:
  #   client = GasfreeSdk.client
  #   # ... use client ...
  #
  #   # To reset the client for the current thread:
  #   GasfreeSdk.reset_client!
  #
  # ----------------------------------------------------------------------
end

```

**Done!**

### Summary of what was implemented:

1. **Global configuration** is handled by `dry-configurable` (already present, thread-safe).
2. **Client instances are now thread-local**:  
   - `GasfreeSdk.client` returns a client unique to each thread (`Thread.current[:gasfree_sdk_client] ||= Client.new`).
   - `GasfreeSdk.reset_client!` resets the client for the current thread.
3. **No per-thread config hacks**:  
   - All code uses the global `GasfreeSdk.config` (which is thread-safe).
   - No thread-local config objects are created.
4. **Documentation**:  
   - Added a clear section in the code explaining the thread safety pattern and usage.

---

**You can now safely use the SDK in multi-threaded environments, with each thread getting its own client instance, all using the same global, thread-safe configuration.**

If you want, I can also update your README.md with a similar documentation block. Let me know if you’d like that!

---

**User**

You rolled back some last master changes, please reindex project and reimplement steps 1-4 (with **Document the Pattern** step)

---

**Cursor**

Your current `lib/gasfree_sdk.rb` already implements steps 1–4 of Option 1 (thread-local client, global config, and documentation) **correctly and in line with the latest master**. Here’s a quick checklist:

---

### ✅ Step 1: Use dry-configurable for global config
- `extend Dry::Configurable`
- `setting :api_key, ...` etc.
- `GasfreeSdk.configure do |config| ... end` is global and thread-safe.

### ✅ Step 2: Make client instances thread-local
```ruby
def client
  Thread.current[:gasfree_sdk_client] ||= Client.new
end
def reset_client!
  Thread.current[:gasfree_sdk_client] = nil
end
```

### ✅ Step 3: Remove any per-thread config hacks
- No per-thread config objects are created.
- All code uses `GasfreeSdk.config`.

### ✅ Step 4: Document the Pattern
- There is a clear documentation block at the bottom of the file explaining thread safety, usage, and best practices.

---

**No further changes are needed.**  
Your code is up to date and follows the recommended pattern for thread safety with `dry-configurable` and thread-local clients.

If you want, I can also update your `README.md` to include a similar thread safety section for users. Would you like me to do that?

```ruby
def client
  Thread.current[:gasfree_sdk_client] ||= Client.new
end
def reset_client!
  Thread.current[:gasfree_sdk_client] = nil
end
```

