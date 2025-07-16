# frozen_string_literal: true

require "spec_helper"
require "gasfree_sdk/utils/amount_converter"

RSpec.describe GasfreeSdk::Utils::AmountConverter do
  describe ".to_base_units" do
    it "converts decimal amount to integer base units correctly" do
      expect(described_class.to_base_units(1.5, 6)).to eq(1_500_000)
      expect(described_class.to_base_units("0.000001", 6)).to eq(1)
    end
  end

  describe ".from_base_units" do
    it "converts base units to float amount correctly" do
      expect(described_class.from_base_units(1_500_000, 6)).to eq(1.5)
    end
  end
end
