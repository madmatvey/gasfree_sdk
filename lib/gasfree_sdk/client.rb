# frozen_string_literal: true

require "base64"
require "openssl"
require "time"
require "uri"

module GasfreeSdk
  # Client for interacting with the GasFree API
  class Client
    # @return [Faraday::Connection] The HTTP client
    attr_reader :connection

    # Initialize a new GasFree client
    def initialize
      @connection = Faraday.new(url: GasfreeSdk.config.api_endpoint) do |f|
        f.request :json
        f.request :retry, GasfreeSdk.config.retry_options
        f.response :json
        f.adapter Faraday.default_adapter
        f.response :logger, ::Logger.new($stdout), bodies: false
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
      Models::GasFreeAddress.new(response["data"])
    end

    # Submit a GasFree transfer
    # @param request [TransferRequest] The transfer request
    # @return [TransferResponse] The transfer response
    def submit_transfer(request)
      response = post("api/v1/gasfree/submit", request.to_h)
      Models::TransferResponse.new(response["data"])
    end

    # Get transfer status
    # @param trace_id [String] The transfer trace ID
    # @return [TransferResponse] The transfer status
    def transfer_status(trace_id)
      response = get("api/v1/gasfree/#{trace_id}")
      Models::TransferResponse.new(response["data"])
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
      data = response.body

      return data if data["code"] == 200

      raise GasfreeSdk.build_error(
        code: data["code"],
        reason: data["reason"],
        message: data["message"]
      )
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
  end
end
