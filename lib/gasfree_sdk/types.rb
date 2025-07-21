# frozen_string_literal: true

require "dry-types"
require "gasfree_sdk/time_parser"

module GasfreeSdk
  # Custom types for the SDK
  module Types
    include Dry.Types()

    # Address type with validation for both Ethereum and TRON addresses
    # Ethereum: 0x followed by 40 hex characters OR just 40 hex characters
    # TRON: Starts with T followed by 33 characters (base58)
    Address = Types::String.constrained(
      format: /\A(0x[0-9a-fA-F]{40}|[0-9a-fA-F]{40}|T[0-9A-Za-z]{33})\z/
    )

    # Hash type with validation
    Hash = Types::String.constrained(format: /\A(0x)?[0-9a-fA-F]{64}\z/)

    # Amount type (string representation of a number, max uint256)
    MAX_UINT256 = (2**256) - 1
    Amount = Types::String.constructor do |v|
      str = v.to_s
      raise Dry::Types::CoercionError, "Amount must be a string of digits" unless str.match?(/\A[0-9]+\z/)

      max = MAX_UINT256.to_s
      unless str.size < max.size || (str.size == max.size && str <= max)
        raise Dry::Types::CoercionError, "Amount exceeds uint256"
      end

      str
    end

    # Timestamp type (Unix timestamp)
    Timestamp = Types::Integer.constrained(gteq: 0)

    # Chain ID type
    ChainId = Types::Integer.constrained(gteq: 1)

    # Nonce type
    Nonce = Types::Integer.constrained(gteq: 0)

    # Version type
    Version = Types::Integer.constrained(included_in: [1])

    # State type
    State = Types::String.constrained(included_in: %w[
                                        WAITING
                                        INPROGRESS
                                        CONFIRMING
                                        SUCCEED
                                        FAILED
                                      ])

    # JSON namespace for API response parsing
    module JSON
      # Convert millisecond timestamp or ISO date string to Time object
      # Takes an integer (milliseconds) or string (ISO format) and returns a Time
      Time = Types.Constructor(::Time) { |value| GasfreeSdk::TimeParser.parse(value) }
      # Convert integer amount to string
      Amount = Types.Constructor(Types::String, &:to_s)
    end
  end
end
