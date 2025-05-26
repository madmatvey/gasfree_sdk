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
      yield config
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
  end

  # Base error class for all SDK errors
  class Error < StandardError; end
  # Your code goes here...
end
