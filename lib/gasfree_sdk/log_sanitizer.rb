# frozen_string_literal: true

module GasfreeSdk
  # Class for masking sensitive data in logs
  # Recursively replaces values of sensitive fields with a mask
  class LogSanitizer
    # Default list of sensitive fields
    DEFAULT_SENSITIVE_FIELDS = %w[
      authorization api-key apikey x-api-key x-access-token access-token token secret x-secret x-api-secret
      private_key privateKey api_secret apiSecret signature sig raw_signature rawSignature password mnemonic seed
      auth_token authToken session_token sessionToken access_token accessToken
    ].freeze

    # Default value to replace sensitive data with
    DEFAULT_MASK = "***REDACTED***"

    # @param sensitive_fields [Array<String>] List of sensitive fields (defaults to DEFAULT_SENSITIVE_FIELDS)
    # @param mask [String] Value to replace sensitive data with (defaults to DEFAULT_MASK)
    def initialize(sensitive_fields: DEFAULT_SENSITIVE_FIELDS, mask: DEFAULT_MASK)
      @sensitive_fields = sensitive_fields
      @mask = mask
    end

    # Recursively masks values of sensitive fields in the given object
    # @param obj [Hash, Array, Object] Object to sanitize
    # @return [Hash, Array, Object] Object with sensitive data masked
    def call(obj)
      case obj
      when Hash
        obj.each_with_object({}) do |(k, v), h|
          h[k] = if sensitive_key?(k)
                   @mask
                 else
                   call(v)
                 end
        end
      when Array
        obj.map { |v| call(v) }
      else
        obj
      end
    end

    private

    # Checks if the key is sensitive
    # @param key [String, Symbol]
    # @return [Boolean]
    def sensitive_key?(key)
      @sensitive_fields.any? { |field| key.to_s.downcase.include?(field.downcase) }
    end
  end
end
