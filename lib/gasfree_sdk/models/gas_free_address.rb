# frozen_string_literal: true

module GasfreeSdk
  module Models
    # Represents an asset in a GasFree account
    class Asset < Dry::Struct
      transform_keys(&:to_sym)

      # @!attribute [r] token_address
      #   @return [String] The token contract address
      attribute :token_address, Types::Address

      # @!attribute [r] token_symbol
      #   @return [String] The token symbol
      attribute :token_symbol, Types::String

      # @!attribute [r] activate_fee
      #   @return [String] The activation fee in the smallest unit
      attribute :activate_fee, Types::Amount

      # @!attribute [r] transfer_fee
      #   @return [String] The transfer fee in the smallest unit
      attribute :transfer_fee, Types::Amount

      # @!attribute [r] decimal
      #   @return [Integer] The token's decimal places
      attribute :decimal, Types::Integer.constrained(gteq: 0)

      # @!attribute [r] frozen
      #   @return [String] Amount currently frozen in pending transfers
      attribute :frozen, Types::Amount
    end

    # Represents a GasFree account
    class GasFreeAddress < Dry::Struct
      transform_keys(&:to_sym)

      # @!attribute [r] account_address
      #   @return [String] The user's EOA address
      attribute :account_address, Types::Address

      # @!attribute [r] gas_free_address
      #   @return [String] The GasFree account address
      attribute :gas_free_address, Types::Address

      # @!attribute [r] active
      #   @return [Boolean] Whether the account is activated
      attribute :active, Types::Bool

      # @!attribute [r] nonce
      #   @return [Integer] The recommended nonce for the next transfer
      attribute :nonce, Types::Nonce

      # @!attribute [r] allow_submit
      #   @return [Boolean] Whether new transfers can be submitted
      attribute :allow_submit, Types::Bool

      # @!attribute [r] assets
      #   @return [Array<Asset>] List of assets in the account
      attribute :assets, Types::Array.of(Asset)
    end
  end
end
