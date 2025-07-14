require "spec_helper"
require "gasfree_sdk/log_sanitizer"

RSpec.describe GasfreeSdk::LogSanitizer do
  let(:sensitive_fields) { %w[private_key token api_secret sig password authorization] }
  let(:mask) { "***REDACTED***" }
  let(:sanitizer) { described_class.new(sensitive_fields: sensitive_fields, mask: mask) }

  shared_examples "returns as is" do |value|
    subject(:result) { sanitizer.call(value) }

    it { is_expected.to eq(value) }
  end

  context "when hash" do
    subject(:masked) { sanitizer.call(data) }

    let(:data) do
      {
        "private_key" => "secret_value",
        "token" => "mytoken",
        "normal" => "visible"
      }
    end

    it { expect(masked["private_key"]).to eq(mask) }
    it { expect(masked["token"]).to eq(mask) }
    it { expect(masked["normal"]).to eq("visible") }
  end

  context "when nested hash" do
    subject(:masked) { sanitizer.call(data) }

    let(:data) do
      {
        "outer" => {
          "api_secret" => "should_hide",
          "inner" => { "sig" => "should_hide_too" }
        }
      }
    end

    it { expect(masked["outer"]["api_secret"]).to eq(mask) }
    it { expect(masked["outer"]["inner"]["sig"]).to eq(mask) }
  end

  context "when array" do
    subject(:masked) { sanitizer.call(data) }

    let(:data) do
      [
        { "password" => "12345" },
        { "normal" => "ok" }
      ]
    end

    it { expect(masked[0]["password"]).to eq(mask) }
    it { expect(masked[1]["normal"]).to eq("ok") }
  end

  context "when non-sensitive" do
    subject(:masked) { sanitizer.call(data) }

    let(:data) { { "foo" => "bar" } }

    it { expect(masked["foo"]).to eq("bar") }
  end

  context "when custom fields and mask" do
    subject(:masked) { sanitizer.call(data) }

    let(:custom_mask) { "MASKED" }
    let(:sanitizer) { described_class.new(sensitive_fields: ["foo"], mask: custom_mask) }
    let(:data) { { "foo" => "secret", "bar" => "open" } }

    it { expect(masked["foo"]).to eq(custom_mask) }
    it { expect(masked["bar"]).to eq("open") }
  end

  context "when string" do
    it_behaves_like "returns as is", "hello"
  end

  context "when integer" do
    it_behaves_like "returns as is", 123
  end

  context "when nil" do
    it_behaves_like "returns as is", nil
  end

  context "when true" do
    it_behaves_like "returns as is", true
  end

  context "when false" do
    it_behaves_like "returns as is", false
  end

  context "when IO object" do
    subject(:result) { sanitizer.call(io) }

    let(:io) { StringIO.new("data") }

    it { is_expected.to eq(io) }
  end
end
