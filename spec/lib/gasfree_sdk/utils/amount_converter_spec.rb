# frozen_string_literal: true

require "spec_helper"
require "gasfree_sdk/utils/amount_converter"

RSpec.describe GasfreeSdk::Utils::AmountConverter do
  describe ".to_base_units" do
    it "converts a human amount to base units" do
      expect(described_class.to_base_units(1.5, 6)).to eq(1_500_000)
    end

    it "raises error for negative amount" do
      expect { described_class.to_base_units(-1, 6) }.to raise_error(ArgumentError)
    end

    it "raises error for non-numeric string" do
      expect { described_class.to_base_units("abc", 6) }.to raise_error(ArgumentError)
    end

    it "raises error for nil" do
      expect { described_class.to_base_units(nil, 6) }.to raise_error(ArgumentError)
    end
  end

  describe ".from_base_units" do
    it "converts base units to a human amount" do
      expect(described_class.from_base_units(1_500_000, 6)).to eq(1.5)
    end
  end
end
