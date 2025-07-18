# frozen_string_literal: true

module GasfreeSdk
  module Utils
    # Represents an asset in a GasFree account
    class AmountConverter
      def self.to_base_units(amount, decimals)
        raise ArgumentError, "amount is nil" if amount.nil?

        num = BigDecimal(amount.to_s)
        raise ArgumentError, "amount must be non-negative" if num.negative?

        (num * (10**decimals)).to_i
      rescue ArgumentError, TypeError
        raise ArgumentError, "amount must be a valid number"
      end

      def self.from_base_units(integer_amount, decimals)
        BigDecimal(integer_amount) / (10**decimals)
      end
    end
  end
end
