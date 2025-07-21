# frozen_string_literal: true

require "time"
require "date"
require "dry-types"

module GasfreeSdk
  # The GasfreeSdk::TimeParser module provides a universal time parsing utility.
  #
  # Key features:
  # - Supports UNIX timestamps in seconds and milliseconds (Integer)
  # - Supports string-based time formats:
  #   - ISO 8601 (e.g., "2023-10-05T14:48:00+02:00")
  #   - RFC 3339 (e.g., "2023-10-05T14:48:00Z")
  #   - RFC 2822 (e.g., "Mon, 02 Jan 2006 15:04:05 -0700")
  #   - Any format supported by Ruby’s standard Time.parse
  #
  # If the format cannot be recognized, it raises a Dry::Types::CoercionError.
  #
  # Example usage:
  #   GasfreeSdk::TimeParser.parse(1_600_000_000) #=> 2020-09-13 15:26:40 +0300
  #   GasfreeSdk::TimeParser.parse("2023-10-05T14:48:00+02:00") #=> 2023-10-05 14:48:00 +0200
  #
  module TimeParser
    # Converts a value into a Time object.
    #
    # @param value [Integer, String] Input value (timestamp or string)
    # @return [Time]
    # @raise [Dry::Types::CoercionError] if the format is not supported
    def self.parse(value)
      case value
      when ::Integer
        if value >= 1_000_000_000_000
          ::Time.at(value / 1000.0)
        else
          ::Time.at(value)
        end
      when ::String
        parse_string(value)
      else
        raise Dry::Types::CoercionError, "Expected Integer or String, got #{value.class}"
      end
    end

    # Attempts to parse a string into a Time object using different strategies.
    #
    # @param value [String]
    # @return [Time]
    # @raise [Dry::Types::CoercionError] if the format is not supported
    def self.parse_string(value)
      parsers = [
        ->(v) { ::Time.iso8601(v) },
        ->(v) { ::Time.rfc2822(v) },
        ->(v) { ::Time.parse(v) }
      ]

      parsers.each do |parser|
        return parser.call(value)
      rescue ArgumentError
        next
      end

      raise Dry::Types::CoercionError, "Unsupported time format: #{value.inspect}"
    end
  end
end
