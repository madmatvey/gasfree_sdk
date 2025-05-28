# frozen_string_literal: true

require "digest"

module GasfreeSdk
  module Crypto
    # Keccak256 implementation for TRON EIP-712 signatures
    class Keccak256 < Digest::Class
      PILN = [10, 7, 11, 17, 18, 3, 5, 16,
              8, 21, 24,  4, 15, 23, 19, 13,
              12, 2, 20, 14, 22, 9, 6, 1].freeze

      ROTC = [1, 3,  6, 10, 15, 21, 28, 36,
              45, 55,  2, 14, 27, 41, 56, 8,
              25, 43, 62, 18, 39, 61, 20, 44].freeze

      RNDC = [0x0000000000000001, 0x0000000000008082, 0x800000000000808a,
              0x8000000080008000, 0x000000000000808b, 0x0000000080000001,
              0x8000000080008081, 0x8000000000008009, 0x000000000000008a,
              0x0000000000000088, 0x0000000080008009, 0x000000008000000a,
              0x000000008000808b, 0x800000000000008b, 0x8000000000008089,
              0x8000000000008003, 0x8000000000008002, 0x8000000000000080,
              0x000000000000800a, 0x800000008000000a, 0x8000000080008081,
              0x8000000000008080, 0x0000000080000001, 0x8000000080008008].freeze

      def initialize
        @size = 256 / 8
        @buffer = "".dup  # Use dup to ensure it's not frozen

        super
      end

      def <<(string)
        @buffer << string.to_s
        self
      end
      alias update <<

      def reset
        @buffer = "".dup  # Create a new unfrozen string instead of clearing
        self
      end

      def finish # rubocop:disable Metrics/AbcSize
        string = Array.new 25, 0
        width = 200 - (@size * 2)
        padding = "\x01".dup

        buffer = @buffer.dup # Create a copy to avoid modifying the original
        buffer << padding << ("\0" * (width - (buffer.size % width)))
        buffer[-1] = (buffer[-1].ord | 0x80).chr

        0.step buffer.size - 1, width do |j|
          quads = buffer[j, width].unpack "Q*"
          (width / 8).times do |i|
            string[i] ^= quads[i]
          end

          keccak string
        end

        string.pack("Q*")[0, @size]
      end

      private

      def keccak(string) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        24.times.each_with_object [] do |round, a|
          # Theta
          5.times do |i|
            a[i] = string[i] ^ string[i + 5] ^ string[i + 10] ^ string[i + 15] ^ string[i + 20]
          end

          5.times do |i|
            t = a[(i + 4) % 5] ^ rotate(a[(i + 1) % 5], 1)
            0.step 24, 5 do |j|
              string[j + i] ^= t
            end
          end

          # Rho Pi
          t = string[1]
          24.times do |i|
            j = PILN[i]
            a[0] = string[j]
            string[j] = rotate t, ROTC[i]
            t = a[0]
          end

          # Chi
          0.step 24, 5 do |j|
            5.times do |i|
              a[i] = string[j + i]
            end

            5.times do |i|
              string[j + i] ^= ~a[(i + 1) % 5] & a[(i + 2) % 5]
            end
          end

          # Iota
          string[0] ^= RNDC[round]
        end
      end

      def rotate(x, y) # rubocop:disable Naming/MethodParameterName
        ((x << y) | (x >> (64 - y))) & ((1 << 64) - 1)
      end
    end
  end
end
