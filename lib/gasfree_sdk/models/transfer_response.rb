# frozen_string_literal: true

module GasfreeSdk
  module Models
    # Represents a GasFree transfer response
    class TransferResponse < Dry::Struct
      transform_keys(&:to_sym)

      # @!attribute [r] id
      #   @return [String] The transfer trace ID
      attribute :id, Types::String

      # @!attribute [r] created_at
      #   @return [Time] When the transfer was created
      attribute? :created_at, Types::JSON::Time

      # @!attribute [r] updated_at
      #   @return [Time] When the transfer was last updated
      attribute? :updated_at, Types::JSON::Time

      # @!attribute [r] account_address
      #   @return [String] The user's EOA address
      attribute? :account_address, Types::Address

      # @!attribute [r] gas_free_address
      #   @return [String] The GasFree account address
      attribute? :gas_free_address, Types::Address

      # @!attribute [r] provider_address
      #   @return [String] The service provider's address
      attribute? :provider_address, Types::Address

      # @!attribute [r] target_address
      #   @return [String] The recipient's address
      attribute? :target_address, Types::Address

      # @!attribute [r] token_address
      #   @return [String] The token contract address
      attribute? :token_address, Types::Address

      # @!attribute [r] amount
      #   @return [String] The transfer amount
      attribute? :amount, Types::JSON::Amount

      # @!attribute [r] max_fee
      #   @return [String] Maximum fee limit
      attribute? :max_fee, Types::JSON::Amount

      # @!attribute [r] signature
      #   @return [String] User's signature
      attribute? :signature, Types::String

      # @!attribute [r] nonce
      #   @return [Integer] Transfer nonce
      attribute? :nonce, Types::Nonce

      # @!attribute [r] expired_at
      #   @return [Time] When the transfer expires
      attribute? :expired_at, Types::JSON::Time

      # @!attribute [r] state
      #   @return [String] Current transfer state
      attribute :state, Types::State

      # @!attribute [r] estimated_activate_fee
      #   @return [String] Estimated activation fee
      attribute? :estimated_activate_fee, Types::JSON::Amount

      # @!attribute [r] estimated_transfer_fee
      #   @return [String] Estimated transfer fee
      attribute? :estimated_transfer_fee, Types::JSON::Amount

      # @!attribute [r] txn_hash
      #   @return [String] On-chain transaction hash
      attribute? :txn_hash, Types::Hash

      # @!attribute [r] txn_block_num
      #   @return [Integer] Block number containing the transaction
      attribute? :txn_block_num, Types::Integer

      # @!attribute [r] txn_block_timestamp
      #   @return [Integer] Block timestamp in milliseconds
      attribute? :txn_block_timestamp, Types::Integer

      # @!attribute [r] txn_state
      #   @return [String] On-chain transaction state
      attribute? :txn_state, Types::String.constrained(
        included_in: %w[INIT NOT_ON_CHAIN ON_CHAIN SOLIDITY ON_CHAIN_FAILED]
      )

      # @!attribute [r] txn_activate_fee
      #   @return [String] Actual activation fee
      attribute? :txn_activate_fee, Types::JSON::Amount

      # @!attribute [r] txn_transfer_fee
      #   @return [String] Actual transfer fee
      attribute? :txn_transfer_fee, Types::JSON::Amount

      # @!attribute [r] txn_total_fee
      #   @return [String] Total actual fee
      attribute? :txn_total_fee, Types::JSON::Amount

      # @!attribute [r] txn_amount
      #   @return [String] Actual transferred amount
      attribute? :txn_amount, Types::JSON::Amount

      # @!attribute [r] txn_total_cost
      #   @return [String] Total cost including fees
      attribute? :txn_total_cost, Types::JSON::Amount
    end
  end
end
