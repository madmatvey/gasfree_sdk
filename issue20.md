# Issue #20: Timestamp Format Inconsistency — Work Log

## Problem

The SDK only supported UNIX milliseconds and ISO8601 for timestamps, but not other common formats. This could break parsing if the API changes the timestamp format.

---

## Plan

**My request:**\
"Help me formulate a plan of action or a task breakdown to solve this issue."

1. Analyze the current implementation of the timestamp parser.
2. Identify popular timestamp formats to support.
3. Extend the parser to handle:
   - UNIX timestamp (seconds and milliseconds)
   - ISO 8601 (with timezone)
   - RFC 3339
   - RFC 2822
4. Add clear error handling for unsupported formats.
5. Write tests for all supported formats.
6. Update documentation.
7. Refactor the code for readability and maintainability.
8. Ensure RuboCop compliance.

---

## Implementation

### 1. Analysis

**My request:**\
"Show me where the parser is located."

The parser was found in `lib/gasfree_sdk/types.rb` as `Types::JSON::Time`, and it only handled milliseconds and ISO8601.

---

### 2. Popular Formats

**My request:**\
"Choose a few of the most popular timestamp formats."

We decided to support:

- UNIX timestamp (seconds and milliseconds)
- ISO 8601 (with timezone)
- RFC 3339
- RFC 2822

---

### 3. Parser Extension

**My requests included:**\
“Yes, agreed. Please go ahead.”\
“Make these changes in the file and start on the tests. Add the tests to the file too.”\
“Some tests are failing. Fix the tests or the code until everything passes.”\
“Can we refactor the new code to reduce nesting and possibly extract it to a separate file?”\
“Can we reduce the nesting for `self.parse_string`?”\
“Alright, write the final version and apply it to the project.”

A new module `GasfreeSdk::TimeParser` was created in `lib/gasfree_sdk/time_parser.rb`:

```ruby
module GasfreeSdk
  module TimeParser
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

    def self.parse_string(value)
      parsers = [
        ->(v) { ::Time.iso8601(v) },
        ->(v) { ::Time.rfc2822(v) },
        ->(v) { ::Time.parse(v) }
      ]

      parsers.each do |parser|
        begin
          return parser.call(value)
        rescue ArgumentError
          next
        end
      end

      raise Dry::Types::CoercionError, "Unsupported time format: #{value.inspect}"
    end
  end
end
```

In `lib/gasfree_sdk/types.rb`:

```ruby
require_relative "time_parser"

module JSON
  Time = Types.Constructor(::Time) { |value| GasfreeSdk::TimeParser.parse(value) }
end
```

---

### 4. Error Handling

**My request:**\
“Some tests are failing. Fix the tests or the code until everything passes.”

All errors for unsupported formats or types now raise `Dry::Types::CoercionError` with a clear message.

---

### 5. Tests

**My requests:**\
“Make these changes in the file and start on the tests. Add the tests to the file too.”\
“Some tests are failing. Fix the tests or the code until everything passes.”

Tests were added in `spec/gasfree_sdk/types/json/time_spec.rb`:

```ruby
# frozen_string_literal: true

require "spec_helper"
require "gasfree_sdk/types"

RSpec.describe GasfreeSdk::Types::JSON::Time do
  subject(:parser) { described_class }

  it "parses UNIX timestamp in seconds" do
    expect(parser.call(1_600_000_000)).to eq(Time.at(1_600_000_000))
  end

  it "parses UNIX timestamp in milliseconds" do
    expect(parser.call(1_600_000_000_000)).to eq(Time.at(1_600_000_000_000 / 1000.0))
  end

  it "parses ISO 8601 format" do
    expect(parser.call("2023-10-05T14:48:00+02:00")).to eq(Time.iso8601("2023-10-05T14:48:00+02:00"))
  end

  it "parses RFC 3339 format" do
    expect(parser.call("2023-10-05T14:48:00Z")).to eq(Time.iso8601("2023-10-05T14:48:00Z"))
  end

  it "parses RFC 2822 format" do
    expect(parser.call("Mon, 02 Jan 2006 15:04:05 -0700")).to eq(Time.rfc2822("Mon, 02 Jan 2006 15:04:05 -0700"))
  end

  it "raises error for unsupported format" do
    expect { parser.call("not a date") }.to raise_error(Dry::Types::CoercionError, /Unsupported time format/)
  end

  it "raises error for wrong type" do
    expect { parser.call(nil) }.to raise_error(Dry::Types::CoercionError, /Expected Integer or String/)
  end
end
```

---

### 6. Documentation

**My request:**\
“Write documentation for `lib/gasfree_sdk/time_parser.rb`.”

Comprehensive documentation was added to the `TimeParser` module, explaining its purpose, supported formats, error handling, and usage examples.

---

### 7. RuboCop Compliance

**My request:**\
"rubocop found style violations — check and fix the code to meet its recommendations."

- Added top-level documentation to the `TimeParser` module.
- Renamed test file according to RSpec conventions: `spec/gasfree_sdk/types/json/time_spec.rb`.

---

### 8. Feedback

While working on the task, AI supported me at every key stage:

- Analysis and planning: With AI's help, I identified which timestamp formats needed support and created a clear implementation plan.

- Parser implementation: AI provided ideas for building a universal parser that supports UNIX timestamps, ISO 8601, RFC 3339, and RFC 2822 formats. This accelerated development.

- Code refactoring: AI suggested how to better structure the code — we extracted the parsing logic into a separate TimeParser module, which reduced complexity and improved readability.

- Testing: I used AI to help design test cases for different formats and detect potential bugs. This ensured all tests passed successfully.

- Documentation: AI helped organize and phrase clear documentation for the TimeParser module, including descriptions and usage examples.

- Style compliance: With AI’s help, I aligned the code with RuboCop standards, including renaming files and adding missing comments.

Working with AI brought mixed emotions: on one hand, I felt excited by the speed at which solutions were generated and how it broadened my technical perspective; on the other hand, I experienced frustration when some outputs were inaccurate, incomplete, or required manual corrections. Still, the overall experience was valuable and productive.
