# frozen_string_literal: true

module GasfreeSdk
  module Models
    # Represents a token supported by GasFree
    class Token < Dry::Struct
      transform_keys(&:to_sym)

      # @!attribute [r] token_address
      #   @return [String] The token contract address
      attribute :token_address, Types::Address

      # @!attribute [r] created_at
      #   @return [Time] When the token was added to GasFree
      attribute :created_at, Types::Time

      # @!attribute [r] updated_at
      #   @return [Time] When the token was last updated
      attribute :updated_at, Types::Time

      # @!attribute [r] activate_fee
      #   @return [String] The activation fee in the smallest unit of the token
      attribute :activate_fee, Types::String

      # @!attribute [r] transfer_fee
      #   @return [String] The transfer fee in the smallest unit of the token
      attribute :transfer_fee, Types::String

      # @!attribute [r] supported
      #   @return [Boolean] Whether the token is currently supported
      attribute :supported, Types::Bool

      # @!attribute [r] symbol
      #   @return [String] The token symbol (e.g., "USDT")
      attribute :symbol, Types::String

      # @!attribute [r] decimal
      #   @return [Integer] The token's decimal places
      attribute :decimal, Types::Integer.constrained(gteq: 0)
      attribute? :decimals, Types::Coercible::Integer.optional
    end
  end
end
