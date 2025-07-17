# frozen_string_literal: true

require "base64"
require "openssl"
require "time"
require "uri"
require_relative "sanitized_logs_middleware"

module GasfreeSdk
  # Client for interacting with the GasFree API
  class Client
    # @return [Faraday::Connection] The HTTP client
    attr_reader :connection

    # Initialize a new GasFree client
    def initialize
      @connection = Faraday.new(url: GasfreeSdk.config.api_endpoint) do |f|
        f.request :json
        f.use GasfreeSdk::RateLimitRetryMiddleware, GasfreeSdk.config.rate_limit_retry_options
        f.request :retry, GasfreeSdk.config.retry_options
        f.response :json
        f.use GasfreeSdk::SanitizedLogsMiddleware, logger: Logger.new($stdout) if ENV["DEBUG_GASFREE_SDK"]
        f.adapter Faraday.default_adapter
      end
    end

    # Get all supported tokens
    # @return [Array<Token>] List of supported tokens
    def tokens
      response = get("api/v1/config/token/all")
      response.dig("data", "tokens").map do |token|
        Models::Token.new(transform_token_data(token))
      end
    end

    # Get all service providers
    # @return [Array<Provider>] List of service providers
    def providers
      response = get("api/v1/config/provider/all")
      response.dig("data", "providers").map do |provider|
        Models::Provider.new(transform_provider_data(provider))
      end
    end

    # Get GasFree account info
    # @param account_address [String] The user's EOA address
    # @return [GasFreeAddress] The GasFree account info
    def address(account_address)
      response = get("api/v1/address/#{account_address}")
      Models::GasFreeAddress.new(transform_address_data(response["data"]))
    end

    # Submit a GasFree transfer
    # @param request [TransferRequest] The transfer request
    # @return [TransferResponse] The transfer response
    def submit_transfer(request)
      response = post("api/v1/gasfree/submit", transform_transfer_request_data(request.to_h))
      Models::TransferResponse.new(transform_transfer_response_data(response["data"]))
    end

    # Get transfer status
    # @param trace_id [String] The transfer trace ID
    # @return [TransferResponse] The transfer status
    def transfer_status(trace_id)
      response = get("api/v1/gasfree/#{trace_id}")
      Models::TransferResponse.new(transform_transfer_response_data(response["data"]))
    end

    private

    # Make a GET request
    # @param path [String] The API path
    # @param params [Hash] Query parameters
    # @return [Hash] The response data
    def get(path, params = {})
      timestamp = Time.now.to_i
      response = connection.get(path, params) do |req|
        sign_request(req, "GET", normalize_path(path), timestamp)
      end
      handle_response(response)
    end

    # Make a POST request
    # @param path [String] The API path
    # @param body [Hash] Request body
    # @return [Hash] The response data
    def post(path, body)
      timestamp = Time.now.to_i
      response = connection.post(path) do |req|
        req.body = body
        sign_request(req, "POST", normalize_path(path), timestamp)
      end
      handle_response(response)
    end

    # Normalize path for signature calculation (needs leading slash)
    # @param path [String] The API path
    # @return [String] Normalized path
    def normalize_path(path)
      path.start_with?("/") ? path : "/#{path}"
    end

    # Sign an API request
    # @param request [Faraday::Request] The request to sign
    # @param method [String] HTTP method
    # @param path [String] Request path
    # @param timestamp [Integer] Request timestamp
    def sign_request(request, method, path, timestamp) # rubocop:disable Metrics/AbcSize
      api_key = GasfreeSdk.config.api_key
      api_secret = GasfreeSdk.config.api_secret

      raise AuthenticationError, "API key and secret are required" if api_key.nil? || api_secret.nil?

      # Extract the base path from the endpoint URL
      # For https://open-test.gasfree.io/nile/ the base path is /nile
      endpoint_uri = URI(GasfreeSdk.config.api_endpoint)
      base_path = endpoint_uri.path.chomp("/") # Remove trailing slash

      # Combine base path with API path for signature
      # e.g., /nile + /api/v1/config/token/all = /nile/api/v1/config/token/all
      full_path = "#{base_path}#{path}"

      # According to GasFree API documentation, the message format is: method + path + timestamp
      message = "#{method}#{full_path}#{timestamp}"
      signature = Base64.strict_encode64(
        OpenSSL::HMAC.digest("SHA256", api_secret, message)
      )

      request.headers["Timestamp"] = timestamp.to_s
      request.headers["Authorization"] = "ApiKey #{api_key}:#{signature}"
    end

    # Handle API response
    # @param response [Faraday::Response] The API response
    # @return [Hash] The response data
    # @raise [APIError] If the response indicates an error
    def handle_response(response)
      # Handle rate limiting specifically
      if response.status == 429
        raise RateLimitError.new(
          "Rate limit exceeded. Please retry after some time.",
          code: "RATE_LIMIT_EXCEEDED",
          reason: "Too many requests"
        )
      end

      data = response.body

      return data if data["code"] == 200

      raise GasfreeSdk.build_error(
        code: data["code"],
        reason: data["reason"],
        message: data["message"]
      )
    end

    # Transform transfer request data from model format to API format
    # @param request_data [Hash] Transfer request data from model
    # @return [Hash] Transformed transfer request data for API
    def transform_transfer_request_data(request_data)
      {
        "token" => request_data[:token],
        "serviceProvider" => request_data[:service_provider], # snake_case to camelCase
        "user" => request_data[:user],
        "receiver" => request_data[:receiver],
        "value" => request_data[:value],
        "maxFee" => request_data[:max_fee], # snake_case to camelCase
        "deadline" => request_data[:deadline],
        "version" => request_data[:version],
        "nonce" => request_data[:nonce],
        "sig" => request_data[:sig]
      }
    end

    # Transform token data from API format to model format
    # @param token_data [Hash] Token data from API
    # @return [Hash] Transformed token data
    def transform_token_data(token_data)
      {
        token_address: token_data["tokenAddress"],
        created_at: Types::JSON::Time.call(token_data["createdAt"]),
        updated_at: Types::JSON::Time.call(token_data["updatedAt"]),
        activate_fee: Types::JSON::Amount.call(token_data["activateFee"]),
        transfer_fee: Types::JSON::Amount.call(token_data["transferFee"]),
        supported: token_data["supported"],
        symbol: token_data["symbol"],
        decimal: token_data["decimal"]
      }
    end

    # Transform provider data from API format to model format
    # @param provider_data [Hash] Provider data from API
    # @return [Hash] Transformed provider data
    def transform_provider_data(provider_data)
      {
        address: provider_data["address"],
        name: provider_data["name"],
        icon: provider_data["icon"],
        website: provider_data["website"],
        config: transform_provider_config_data(provider_data["config"])
      }
    end

    # Transform provider config data from API format to model format
    # @param config_data [Hash] Provider config data from API
    # @return [Hash] Transformed provider config data
    def transform_provider_config_data(config_data)
      {
        max_pending_transfer: config_data["maxPendingTransfer"],
        min_deadline_duration: config_data["minDeadlineDuration"],
        max_deadline_duration: config_data["maxDeadlineDuration"],
        default_deadline_duration: config_data["defaultDeadlineDuration"]
      }
    end

    # Transform address data from API format to model format
    # @param address_data [Hash] Address data from API
    # @return [Hash] Transformed address data
    def transform_address_data(address_data)
      {
        account_address: address_data["accountAddress"],
        gas_free_address: address_data["gasFreeAddress"],
        active: address_data["active"],
        nonce: address_data["nonce"],
        allow_submit: address_data["allowSubmit"],
        assets: address_data["assets"]&.map { |asset| transform_asset_data(asset) } || []
      }
    end

    # Transform asset data from API format to model format
    # @param asset_data [Hash] Asset data from API
    # @return [Hash] Transformed asset data
    def transform_asset_data(asset_data)
      {
        token_address: asset_data["tokenAddress"],
        token_symbol: asset_data["tokenSymbol"],
        activate_fee: Types::JSON::Amount.call(asset_data["activateFee"]),
        transfer_fee: Types::JSON::Amount.call(asset_data["transferFee"]),
        decimal: asset_data["decimal"],
        frozen: Types::JSON::Amount.call(asset_data["frozen"])
      }
    end

    # Transform transfer response data from API format to model format
    # @param response_data [Hash] Transfer response data from API
    # @return [Hash] Transformed transfer response data
    def transform_transfer_response_data(response_data)
      basic_fields = extract_basic_transfer_fields(response_data)
      transaction_fields = extract_transaction_fields(response_data)

      basic_fields.merge(transaction_fields).compact
    end

    # Extract basic transfer fields from response data
    # @param response_data [Hash] Transfer response data from API
    # @return [Hash] Basic transfer fields
    def extract_basic_transfer_fields(response_data)
      {
        id: response_data["id"],
        created_at: get_field_value(response_data, "createdAt", "created_at"),
        updated_at: get_field_value(response_data, "updatedAt", "updated_at"),
        account_address: get_field_value(response_data, "accountAddress", "account_address"),
        gas_free_address: get_field_value(response_data, "gasFreeAddress", "gas_free_address"),
        provider_address: get_field_value(response_data, "providerAddress", "provider_address"),
        target_address: get_field_value(response_data, "targetAddress", "target_address"),
        token_address: get_field_value(response_data, "tokenAddress", "token_address"),
        amount: response_data["amount"],
        max_fee: get_field_value(response_data, "maxFee", "max_fee"),
        signature: response_data["signature"],
        nonce: response_data["nonce"],
        expired_at: get_field_value(response_data, "expiredAt", "expired_at"),
        state: response_data["state"]
      }
    end

    # Extract transaction-related fields from response data
    # @param response_data [Hash] Transfer response data from API
    # @return [Hash] Transaction fields
    def extract_transaction_fields(response_data)
      {
        estimated_activate_fee: get_field_value(response_data, "estimatedActivateFee", "estimated_activate_fee"),
        estimated_transfer_fee: get_field_value(response_data, "estimatedTransferFee", "estimated_transfer_fee"),
        txn_hash: get_field_value(response_data, "txnHash", "txn_hash"),
        txn_block_num: get_field_value(response_data, "txnBlockNum", "txn_block_num"),
        txn_block_timestamp: get_field_value(response_data, "txnBlockTimestamp", "txn_block_timestamp"),
        txn_state: get_field_value(response_data, "txnState", "txn_state"),
        txn_activate_fee: get_field_value(response_data, "txnActivateFee", "txn_activate_fee"),
        txn_transfer_fee: get_field_value(response_data, "txnTransferFee", "txn_transfer_fee"),
        txn_total_fee: get_field_value(response_data, "txnTotalFee", "txn_total_fee"),
        txn_amount: get_field_value(response_data, "txnAmount", "txn_amount"),
        txn_total_cost: get_field_value(response_data, "txnTotalCost", "txn_total_cost")
      }
    end

    # Get field value with fallback to snake_case version
    # @param data [Hash] The data hash
    # @param camel_case_key [String] The camelCase key
    # @param snake_case_key [String] The snake_case key
    # @return [Object] The field value
    def get_field_value(data, camel_case_key, snake_case_key)
      data[camel_case_key] || data[snake_case_key]
    end
  end
end
