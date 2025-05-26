# frozen_string_literal: true

require "base64"
require "openssl"
require "time"

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
      end
    end

    # Get all supported tokens
    # @return [Array<Token>] List of supported tokens
    def tokens
      response = get("/api/v1/config/token/all")
      response.dig("data", "tokens").map { |token| Models::Token.new(token) }
    end

    # Get all service providers
    # @return [Array<Provider>] List of service providers
    def providers
      response = get("/api/v1/config/provider/all")
      response.dig("data", "providers").map { |provider| Models::Provider.new(provider) }
    end

    # Get GasFree account info
    # @param account_address [String] The user's EOA address
    # @return [GasFreeAddress] The GasFree account info
    def address(account_address)
      response = get("/api/v1/address/#{account_address}")
      Models::GasFreeAddress.new(response["data"])
    end

    # Submit a GasFree transfer
    # @param request [TransferRequest] The transfer request
    # @return [TransferResponse] The transfer response
    def submit_transfer(request)
      response = post("/api/v1/gasfree/submit", request.to_h)
      Models::TransferResponse.new(response["data"])
    end

    # Get transfer status
    # @param trace_id [String] The transfer trace ID
    # @return [TransferResponse] The transfer status
    def transfer_status(trace_id)
      response = get("/api/v1/gasfree/#{trace_id}")
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
        sign_request(req, "GET", path, timestamp)
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
        sign_request(req, "POST", path, timestamp)
      end
      handle_response(response)
    end

    # Sign an API request
    # @param request [Faraday::Request] The request to sign
    # @param method [String] HTTP method
    # @param path [String] Request path
    # @param timestamp [Integer] Request timestamp
    def sign_request(request, method, path, timestamp)
      api_key = GasfreeSdk.config.api_key
      api_secret = GasfreeSdk.config.api_secret

      raise AuthenticationError, "API key and secret are required" if api_key.nil? || api_secret.nil?

      message = "#{method}#{path}#{timestamp}"
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
  end
end 