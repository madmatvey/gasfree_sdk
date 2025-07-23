# frozen_string_literal: true

# rubocop:disable RSpec/FilePath, RSpec/SpecFilePathFormat

require "spec_helper"

RSpec.describe GasfreeSdk::Models::TransferRequest do
  let(:tron_address_regex) { /\AT[1-9A-HJ-NP-Za-km-z]{33}\z/ }

  it "uses valid TRON addresses in the example" do
    # Адреса из examples/basic_usage.rb
    user_address = "TZ3oPnE1SdAUL1YRd9GJQHenxrXjy4paAn"
    receiver_address = "TX554G9uKsEv1U6TBQnNPC7dkhbvBFhgrD"

    expect(user_address).to match(tron_address_regex)
    expect(receiver_address).to match(tron_address_regex)
  end

  it "does not raise format errors when creating a TransferRequest" do
    # Минимальный mock для токена и провайдера
    token = Struct.new(:token_address, :transfer_fee).new(
      "TX554G9uKsEv1U6TBQnNPC7dkhbvBFhgrD", "1000"
    )
    provider_config = Struct.new(:default_deadline_duration).new(300)
    provider = Struct.new(:address, :config).new(
      "TX554G9uKsEv1U6TBQnNPC7dkhbvBFhgrD",
      provider_config
    )

    message = {
      token: token.token_address,
      service_provider: provider.address,
      user: "TZ3oPnE1SdAUL1YRd9GJQHenxrXjy4paAn",
      receiver: "TX554G9uKsEv1U6TBQnNPC7dkhbvBFhgrD",
      value: "1000000",
      max_fee: token.transfer_fee,
      deadline: Time.now.to_i + provider.config.default_deadline_duration,
      version: 1,
      nonce: 0,
      sig: "0x#{"a" * 130}"
    }

    expect do
      described_class.new(message)
    end.not_to raise_error
  end
end
# rubocop:enable RSpec/FilePath, RSpec/SpecFilePathFormat
