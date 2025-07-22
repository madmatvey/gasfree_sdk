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

  it "raises error for invalid api_endpoint URL" do
    expect {
      described_class.configure do |config|
        config.api_endpoint = "not a url"
      end
    }.to raise_error(GasfreeSdk::Error, /Invalid api_endpoint URL/)

    expect {
      described_class.configure do |config|
        config.api_endpoint = "ftp://example.com"
      end
    }.to raise_error(GasfreeSdk::Error, /Invalid api_endpoint URL/)

    expect {
      described_class.configure do |config|
        config.api_endpoint = "http:///missinghost"
      end
    }.to raise_error(GasfreeSdk::Error, /Invalid api_endpoint URL/)
  end

  it "accepts valid http and https api_endpoint URLs" do
    expect {
      described_class.configure do |config|
        config.api_endpoint = "http://example.com/"
      end
    }.not_to raise_error

    expect {
      described_class.configure do |config|
        config.api_endpoint = "https://example.com/"
      end
    }.not_to raise_error
  end
end
