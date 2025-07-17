# frozen_string_literal: true

require "spec_helper"
require "gasfree_sdk/utils/amount_converter"

RSpec.describe GasfreeSdk::Utils::AmountConverter do
  describe ".to_base_units" do
    it "converts a human amount to base units" do
      expect(described_class.to_base_units(1.5, 6)).to eq(1_500_000)
    end
  end
end
