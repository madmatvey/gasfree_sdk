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
