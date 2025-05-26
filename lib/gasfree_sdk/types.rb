# frozen_string_literal: true

require "dry-types"

module GasfreeSdk
  # Custom types for the SDK
  module Types
    include Dry.Types()

    # Address type with validation
    Address = Types::String.constrained(format: /\A(0x)?[0-9a-fA-F]{40}\z/)

    # Hash type with validation
    Hash = Types::String.constrained(format: /\A(0x)?[0-9a-fA-F]{64}\z/)

    # Amount type (string representation of a number)
    Amount = Types::String.constrained(format: /\A[0-9]+\z/)

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
  end
end 