# frozen_string_literal: true

module GasfreeSdk
  module Utils
    # Utility class for converting token amounts between human format and base units
    class AmountConverter
      def self.to_base_units(amount, decimals)
        raise ArgumentError, "Decimals must be >= 0" if decimals.negative?
        raise ArgumentError, "Amount must be numeric" unless amount.respond_to?(:to_d)

        (BigDecimal(amount.to_s) * (10**decimals)).to_i
      end

      # Преобразует base units в человекочитаемую сумму (например, 1_500_000 -> 1.5 USDT)
      def self.from_base_units(integer_amount, decimals)
        BigDecimal(integer_amount.to_s) / (10**decimals)
      end
    end
  end
end
