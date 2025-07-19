# frozen_string_literal: true

require "spec_helper"
require "gasfree_sdk/models/transfer_request"

RSpec.describe GasfreeSdk::Models::TransferRequest do
  describe ".build_with_token" do
    let(:token) do
      GasfreeSdk::Models::Token.new(
        token_address: "TLa2f6VPqDgRE67v1736s7bJ8Ray5wYjU7",
        created_at: Time.now,
        updated_at: Time.now,
        activate_fee: "0",
        transfer_fee: "0",
        supported: true,
        symbol: "USDT",
        decimal: 6
      )
    end

    it "correctly converts human_amount to base units" do
      req = described_class.build_with_token(
        token: token,
        human_amount: 2.5,
        service_provider: "TLa2f6VPqDgRE67v1736s7bJ8Ray5wYjU7",
        user: "TLa2f6VPqDgRE67v1736s7bJ8Ray5wYjU7",
        receiver: "TLa2f6VPqDgRE67v1736s7bJ8Ray5wYjU7",
        max_fee: "0",
        deadline: Time.now.to_i + 600,
        version: 1,
        nonce: 0,
        sig: "signature"
      )
      expect(req.value).to eq("2500000")
    end

    it "raises an error for invalid amount format" do
      expect do
        described_class.build_with_token(token: token, human_amount: "abc")
      end.to raise_error(ArgumentError)
    end
  end
end
