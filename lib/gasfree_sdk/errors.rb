# frozen_string_literal: true

# GasFree SDK error classes and utilities
module GasfreeSdk
  # Base error class for all SDK errors
  class Error < StandardError
    attr_reader :code, :reason

    def initialize(message, code: nil, reason: nil)
      super(message)
      @code = code
      @reason = reason
    end
  end

  # Configuration related errors
  class ConfigurationError < Error; end

  # Authentication related errors
  class AuthenticationError < Error; end

  # API related errors
  class APIError < Error; end

  # Invalid signature errors
  class InvalidSignatureError < APIError; end

  # Deadline exceeded errors
  class DeadlineExceededError < APIError; end

  # Insufficient balance errors
  class InsufficientBalanceError < APIError; end

  # Address not found errors
  class AddressNotFoundError < APIError; end

  # Transfer not found errors
  class TransferNotFoundError < APIError; end

  class << self
    # Map error codes to specific error classes
    ERROR_CODE_MAP = {
      "AUTHENTICATION_ERROR" => AuthenticationError,
      "INVALID_SIGNATURE" => InvalidSignatureError,
      "DEADLINE_EXCEEDED" => DeadlineExceededError,
      "INSUFFICIENT_BALANCE" => InsufficientBalanceError,
      "ADDRESS_NOT_FOUND" => AddressNotFoundError,
      "TRANSFER_NOT_FOUND" => TransferNotFoundError
    }.freeze

    # Factory method to create appropriate error instances
    # @param code [String] Error code from API
    # @param reason [String] Error reason from API
    # @param message [String] Error message from API
    # @return [Error] Appropriate error instance
    def build_error(code:, reason:, message:)
      error_class = determine_error_class(code, reason)
      error_class.new(message, code: code, reason: reason)
    end

    private

    def determine_error_class(code, reason)
      return ERROR_CODE_MAP[code] if ERROR_CODE_MAP.key?(code)

      case reason
      when /signature/i then InvalidSignatureError
      when /deadline/i then DeadlineExceededError
      when /balance/i then InsufficientBalanceError
      when /not found/i
        determine_not_found_error(reason)
      else
        APIError
      end
    end

    def determine_not_found_error(reason)
      case reason
      when /address/i then AddressNotFoundError
      when /transfer/i then TransferNotFoundError
      else APIError
      end
    end
  end
end
