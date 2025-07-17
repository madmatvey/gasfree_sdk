# frozen_string_literal: true

module GasfreeSdk
  module Utils
    # Represents an asset in a GasFree account
    class AmountConverter
      def self.to_base_units(amount, decimals)
        (BigDecimal(amount.to_s) * (10**decimals)).to_i
      end

      def self.from_base_units(integer_amount, decimals)
        BigDecimal(integer_amount) / (10**decimals)
      end
    end
  end
end
