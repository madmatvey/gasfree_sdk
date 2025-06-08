# frozen_string_literal: true

module GasfreeSdk
  # Base58 implementation for TRON address encoding/decoding
  module Base58
    ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

    class << self
      # Convert Base58 string to binary data
      # @param s [String] Base58 encoded string
      # @return [String] Binary data
      def base58_to_binary(string)
        int_val = 0
        base = ALPHABET.size
        string.each_char do |char|
          int_val = (int_val * base) + ALPHABET.index(char)
        end

        # Convert to bytes
        bytes = []
        while int_val.positive?
          bytes.unshift(int_val & 0xff)
          int_val >>= 8
        end

        # Handle leading zeros
        string.each_char do |char|
          break if char != "1"

          bytes.unshift(0)
        end

        bytes.pack("C*")
      end

      # Convert binary data to Base58 string
      # @param bytes [String] Binary data
      # @return [String] Base58 encoded string
      def binary_to_base58(bytes)
        # Convert bytes to integer
        int_val = 0
        bytes.each_byte do |byte|
          int_val = (int_val << 8) + byte
        end

        # Convert to base58
        result = ""
        base = ALPHABET.size
        while int_val.positive?
          int_val, remainder = int_val.divmod(base)
          result = ALPHABET[remainder] + result
        end

        # Handle leading zeros
        bytes.each_byte do |byte|
          break if byte != 0

          result = "1#{result}"
        end

        result.empty? ? "1" : result
      end
    end
  end
end
