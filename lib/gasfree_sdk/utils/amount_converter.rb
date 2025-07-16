# frozen_string_literal: true

module GasfreeSdk
  module Utils
    class AmountConverter
      def self.to_base_units(amount, decimals)
        raise ArgumentError, "Decimals must be >= 0" if decimals < 0
        raise ArgumentError, "Amount must be numeric" unless amount.respond_to?(:to_d)

        (BigDecimal(amount.to_s) * (10 ** decimals)).to_i
      end

      # Преобразует base units в человекочитаемую сумму (например, 1_500_000 -> 1.5 USDT)
      def self.from_base_units(integer_amount, decimals)
        BigDecimal(integer_amount.to_s) / (10 ** decimals)
      end
    end
  end
end
