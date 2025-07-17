# frozen_string_literal: true

require "gasfree_sdk/utils/amount_converter"

module GasfreeSdk
  module Models
    # Represents a GasFree transfer request
    class TransferRequest < Dry::Struct
      transform_keys(&:to_sym)

      # @!attribute [r] token
      #   @return [String] The token contract address
      attribute :token, Types::Address

      # @!attribute [r] service_provider
      #   @return [String] The service provider's address
      attribute :service_provider, Types::Address

      # @!attribute [r] user
      #   @return [String] The user's EOA address
      attribute :user, Types::Address

      # @!attribute [r] receiver
      #   @return [String] The recipient's address
      attribute :receiver, Types::Address

      # @!attribute [r] value
      #   @return [String] The transfer amount in smallest unit
      attribute :value, Types::Amount

      # @!attribute [r] max_fee
      #   @return [String] Maximum fee limit in smallest unit
      attribute :max_fee, Types::Amount

      # @!attribute [r] deadline
      #   @return [Integer] Transfer expiration timestamp
      attribute :deadline, Types::Timestamp

      # @!attribute [r] version
      #   @return [Integer] Signature version
      attribute :version, Types::Version

      # @!attribute [r] nonce
      #   @return [Integer] Transfer nonce
      attribute :nonce, Types::Nonce

      # @!attribute [r] sig
      #   @return [String] User's signature
      attribute :sig, Types::String

      def self.build_with_token(token:, human_amount:, **args)
        base_amount = GasfreeSdk::Utils::AmountConverter.to_base_units(human_amount, token.decimals)
        new(token: token.token_address, value: base_amount, **args)
      end
    end
  end
end
