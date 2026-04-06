# frozen_string_literal: true

module GasfreeSdk
  module Utils
    # Represents an asset in a GasFree account
    class AmountConverter
      def self.to_base_units(amount, decimal)
        num = parse_amount!(amount)

        raise ArgumentError, "amount must be positive" unless num.positive?

        (num * (10**decimal)).to_i
      end

      def self.parse_amount!(amount)
        raise ArgumentError, "amount is nil" if amount.nil?

        BigDecimal(amount.to_s)
      rescue ArgumentError, TypeError
        raise ArgumentError, "amount must be a valid number"
      end

      def self.from_base_units(integer_amount, decimal)
        raise ArgumentError, "decimal is nil" if decimal.nil?

        BigDecimal(integer_amount) / (10**decimal)
      end
    end
  end
end
