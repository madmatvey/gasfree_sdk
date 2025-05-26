# frozen_string_literal: true

RSpec.describe GasfreeSdk do
  it "has a version number" do
    expect(GasfreeSdk::VERSION).not_to be nil
  end

  it "can be configured" do
    GasfreeSdk.configure do |config|
      config.api_key = "test-key"
      config.api_secret = "test-secret"
    end
    
    expect(GasfreeSdk.config.api_key).to eq("test-key")
    expect(GasfreeSdk.config.api_secret).to eq("test-secret")
  end
end
