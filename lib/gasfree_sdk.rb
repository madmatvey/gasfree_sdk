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
    backoff_factor: 2,
    retry_statuses: [429],
    rate_limit_retry_header: "Retry-After"
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
  # Your code goes here...
end
