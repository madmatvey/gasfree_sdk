# frozen_string_literal: true

RSpec.describe GasfreeSdk do
  it "has a version number" do
    expect(GasfreeSdk::VERSION).not_to be_nil
  end

  it "can be configured" do
    described_class.configure do |config|
      config.api_key = "test-key"
      config.api_secret = "test-secret"
    end

    expect(described_class.config.api_key).to eq("test-key")
    expect(described_class.config.api_secret).to eq("test-secret")
  end

  describe "api_endpoint URL validation" do
    it "accepts a valid HTTP URL" do
      expect do
        described_class.configure { |config| config.api_endpoint = "https://valid.example.com/" }
      end.not_to raise_error
    end

    it "accepts a valid HTTPS URL" do
      expect do
        described_class.configure { |config| config.api_endpoint = "http://valid.example.com/" }
      end.not_to raise_error
    end

    it "raises error for malformed URL" do
      expect do
        described_class.configure { |config| config.api_endpoint = "not a url" }
      end.to raise_error(ArgumentError, /Invalid API endpoint URL/)
    end

    it "raises error for unsupported scheme" do
      expect do
        described_class.configure { |config| config.api_endpoint = "ftp://example.com" }
      end.to raise_error(ArgumentError, /Invalid API endpoint URL/)
    end
  end
end
