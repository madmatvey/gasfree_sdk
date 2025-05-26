# frozen_string_literal: true

module GasfreeSdk
  # Base error class for all SDK errors
  class Error < StandardError; end

  # Raised when API credentials are missing or invalid
  class AuthenticationError < Error; end

  # Raised when API request fails
  class APIError < Error
    attr_reader :code, :reason

    def initialize(code:, reason:, message:)
      @code = code
      @reason = reason
      super(message)
    end
  end

  # Specific API errors
  class ProviderAddressNotMatchError < APIError; end
  class DeadlineExceededError < APIError; end
  class InvalidSignatureError < APIError; end
  class UnsupportedTokenError < APIError; end
  class TooManyPendingTransfersError < APIError; end
  class VersionNotSupportedError < APIError; end
  class NonceNotMatchError < APIError; end
  class MaxFeeExceededError < APIError; end
  class InsufficientBalanceError < APIError; end

  # Error factory
  class << self
    def build_error(code:, reason:, message:)
      error_class = case reason
                   when "ProviderAddressNotMatchException"
                     ProviderAddressNotMatchError
                   when "DeadlineExceededException"
                     DeadlineExceededError
                   when "InvalidSignatureException"
                     InvalidSignatureError
                   when "UnsupportedTokenException"
                     UnsupportedTokenError
                   when "TooManyPendingTransferException"
                     TooManyPendingTransfersError
                   when "VersionNotSupportedException"
                     VersionNotSupportedError
                   when "NonceNotMatchException"
                     NonceNotMatchError
                   when "MaxFeeExceededException"
                     MaxFeeExceededError
                   when "InsufficientBalanceException"
                     InsufficientBalanceError
                   else
                     APIError
                   end

      error_class.new(code: code, reason: reason, message: message)
    end
  end
end 