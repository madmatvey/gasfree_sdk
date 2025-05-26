# frozen_string_literal: true

module GasfreeSdk
  module Models
    # Configuration for a service provider
    class ProviderConfig < Dry::Struct
      transform_keys(&:to_sym)

      # @!attribute [r] max_pending_transfer
      #   @return [Integer] Maximum number of pending transfers allowed
      attribute :max_pending_transfer, Types::Integer.constrained(gteq: 0)

      # @!attribute [r] min_deadline_duration
      #   @return [Integer] Minimum deadline duration in seconds
      attribute :min_deadline_duration, Types::Integer.constrained(gteq: 0)

      # @!attribute [r] max_deadline_duration
      #   @return [Integer] Maximum deadline duration in seconds
      attribute :max_deadline_duration, Types::Integer.constrained(gteq: 0)

      # @!attribute [r] default_deadline_duration
      #   @return [Integer] Default deadline duration in seconds
      attribute :default_deadline_duration, Types::Integer.constrained(gteq: 0)
    end

    # Represents a GasFree service provider
    class Provider < Dry::Struct
      transform_keys(&:to_sym)

      # @!attribute [r] address
      #   @return [String] The provider's address
      attribute :address, Types::Address

      # @!attribute [r] name
      #   @return [String] The provider's name
      attribute :name, Types::String

      # @!attribute [r] icon
      #   @return [String] URL to the provider's icon
      attribute :icon, Types::String

      # @!attribute [r] website
      #   @return [String] The provider's website
      attribute :website, Types::String

      # @!attribute [r] config
      #   @return [ProviderConfig] The provider's configuration
      attribute :config, ProviderConfig
    end
  end
end
