# frozen_string_literal: true

RSpec.describe GasfreeSdk::Models do
  describe GasfreeSdk::Models::Token do
    let(:valid_attributes) do
      {
        token_address: "0x1234567890123456789012345678901234567890",
        created_at: "2024-01-01T00:00:00Z",
        updated_at: "2024-01-01T00:00:00Z",
        activate_fee: "1000000",
        transfer_fee: "500000",
        supported: true,
        symbol: "USDT",
        decimal: 6
      }
    end

    it "creates a token with valid attributes" do
      token = described_class.new(valid_attributes)
      expect(token.token_address).to eq(valid_attributes[:token_address])
      expect(token.activate_fee).to eq(valid_attributes[:activate_fee])
      expect(token.symbol).to eq(valid_attributes[:symbol])
    end

    it "raises error with invalid address" do
      expect do
        described_class.new(valid_attributes.merge(token_address: "invalid"))
      end.to raise_error(Dry::Struct::Error)
    end
  end

  describe GasfreeSdk::Models::Provider do
    let(:valid_config) do
      {
        max_pending_transfer: 1,
        min_deadline_duration: 60,
        max_deadline_duration: 600,
        default_deadline_duration: 180
      }
    end

    let(:valid_attributes) do
      {
        address: "0x1234567890123456789012345678901234567890",
        name: "Provider-1",
        icon: "",
        website: "",
        config: valid_config
      }
    end

    it "creates a provider with valid attributes" do
      provider = described_class.new(valid_attributes)
      expect(provider.address).to eq(valid_attributes[:address])
      expect(provider.name).to eq(valid_attributes[:name])
      expect(provider.config.max_pending_transfer).to eq(valid_config[:max_pending_transfer])
    end

    it "raises error with invalid config" do
      expect do
        described_class.new(valid_attributes.merge(
                              config: valid_config.merge(max_pending_transfer: -1)
                            ))
      end.to raise_error(Dry::Struct::Error)
    end
  end

  describe GasfreeSdk::Models::GasFreeAddress do
    let(:valid_asset) do
      {
        token_address: "0x1234567890123456789012345678901234567890",
        token_symbol: "USDT",
        activate_fee: "1000000",
        transfer_fee: "500000",
        decimal: 6,
        frozen: "0"
      }
    end

    let(:valid_attributes) do
      {
        account_address: "0x1234567890123456789012345678901234567890",
        gas_free_address: "0x1234567890123456789012345678901234567890",
        active: true,
        nonce: 0,
        allow_submit: true,
        assets: [valid_asset]
      }
    end

    it "creates a GasFree address with valid attributes" do
      address = described_class.new(valid_attributes)
      expect(address.account_address).to eq(valid_attributes[:account_address])
      expect(address.active).to eq(valid_attributes[:active])
      expect(address.assets.first.token_symbol).to eq(valid_asset[:token_symbol])
    end

    it "raises error with invalid nonce" do
      expect do
        described_class.new(valid_attributes.merge(nonce: -1))
      end.to raise_error(Dry::Struct::Error)
    end
  end

  describe GasfreeSdk::Models::TransferRequest do
    let(:valid_attributes) do
      {
        token: "0x1234567890123456789012345678901234567890",
        service_provider: "0x1234567890123456789012345678901234567890",
        user: "0x1234567890123456789012345678901234567890",
        receiver: "0x1234567890123456789012345678901234567890",
        value: "1000000",
        max_fee: "100000",
        deadline: Time.now.to_i + 180,
        version: 1,
        nonce: 0,
        sig: "0x1234567890123456789012345678901234567890123456789012345678901234"
      }
    end

    it "creates a transfer request with valid attributes" do
      request = described_class.new(valid_attributes)
      expect(request.token).to eq(valid_attributes[:token])
      expect(request.value).to eq(valid_attributes[:value])
      expect(request.version).to eq(valid_attributes[:version])
    end

    it "raises error with invalid version" do
      expect do
        described_class.new(valid_attributes.merge(version: 2))
      end.to raise_error(Dry::Struct::Error)
    end
  end

  describe GasfreeSdk::Models::TransferResponse do
    let(:valid_attributes) do
      {
        id: "transfer-id",
        created_at: "2024-01-01T00:00:00Z",
        updated_at: "2024-01-01T00:00:00Z",
        account_address: "0x1234567890123456789012345678901234567890",
        gas_free_address: "0x1234567890123456789012345678901234567890",
        provider_address: "0x1234567890123456789012345678901234567890",
        target_address: "0x1234567890123456789012345678901234567890",
        token_address: "0x1234567890123456789012345678901234567890",
        amount: "1000000",
        max_fee: "100000",
        signature: "0x1234567890123456789012345678901234567890123456789012345678901234",
        nonce: 0,
        expired_at: "2024-01-01T00:03:00Z",
        state: "WAITING",
        estimated_activate_fee: "50000",
        estimated_transfer_fee: "30000"
      }
    end

    it "creates a transfer response with valid attributes" do
      response = described_class.new(valid_attributes)
      expect(response.id).to eq(valid_attributes[:id])
      expect(response.state).to eq(valid_attributes[:state])
      expect(response.amount).to eq(valid_attributes[:amount])
    end

    it "raises error with invalid state" do
      expect do
        described_class.new(valid_attributes.merge(state: "INVALID"))
      end.to raise_error(Dry::Struct::Error)
    end

    it "allows optional transaction fields" do
      response = described_class.new(valid_attributes.merge(
                                       txn_hash: "0x1234567890123456789012345678901234567890123456789012345678901234",
                                       txn_block_num: 12_345,
                                       txn_state: "ON_CHAIN",
                                       txn_amount: "1000000"
                                     ))
      expect(response.txn_hash).to be_a(String)
      expect(response.txn_block_num).to eq(12_345)
      expect(response.txn_state).to eq("ON_CHAIN")
      expect(response.txn_amount).to eq("1000000")
    end
  end
end
