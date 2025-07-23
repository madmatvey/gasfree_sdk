# frozen_string_literal: true

module GasfreeSdk
  module Utils
    # Represents an asset in a GasFree account
    class AmountConverter
      def self.to_base_units(amount, decimal)
        raise ArgumentError, "amount is nil" if amount.nil?

        num = BigDecimal(amount.to_s)
        raise ArgumentError, "amount must be non-negative" if num.negative?

        (num * (10**decimal)).to_i
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
