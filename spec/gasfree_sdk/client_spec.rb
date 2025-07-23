# frozen_string_literal: true

RSpec.describe GasfreeSdk::Client do
  let(:client) { described_class.new }

  before do
    GasfreeSdk.configure do |config|
      config.api_key = "test-key"
      config.api_secret = "test-secret"
      config.api_endpoint = "https://test.gasfree.io/"
    end
  end

  describe "#tokens" do
    it "returns a list of tokens" do
      # Mock the HTTP response with the actual API format (camelCase fields and millisecond timestamps)
      stub_request(:get, "https://test.gasfree.io/api/v1/config/token/all")
        .to_return(
          status: 200,
          body: {
            code: 200,
            data: {
              tokens: [
                {
                  tokenAddress: "TXYZopYRdj2D9XRtbG411XZZ3kM5VkAeBf",
                  createdAt: 1_733_474_531_733,
                  updatedAt: 1_748_426_720_073,
                  activateFee: 1_100_000,
                  transferFee: 2000,
                  supported: true,
                  symbol: "USDT",
                  decimal: 6
                }
              ]
            }
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      tokens = client.tokens
      expect(tokens).to be_an(Array)
      expect(tokens.first).to be_a(GasfreeSdk::Models::Token)
      expect(tokens.first.symbol).to eq("USDT")
      expect(tokens.first.token_address).to eq("TXYZopYRdj2D9XRtbG411XZZ3kM5VkAeBf")
      expect(tokens.first.activate_fee).to eq("1100000")
      expect(tokens.first.transfer_fee).to eq("2000")
      expect(tokens.first.created_at).to be_a(Time)
      expect(tokens.first.updated_at).to be_a(Time)
    end
  end

  describe "#providers" do
    it "returns a list of providers" do
      stub_request(:get, "https://test.gasfree.io/api/v1/config/provider/all")
        .to_return(
          status: 200,
          body: {
            code: 200,
            data: {
              providers: [
                {
                  address: "TKtWbdzEq5ss9vTS9kwRhBp5mXmBfBns3E",
                  name: "gasfree-provider",
                  icon: "https://example.com/icon.png",
                  website: "https://gasfree.io",
                  config: {
                    maxPendingTransfer: 1,
                    minDeadlineDuration: 60,
                    maxDeadlineDuration: 3600,
                    defaultDeadlineDuration: 180
                  }
                }
              ]
            }
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      providers = client.providers
      expect(providers).to be_an(Array)
      expect(providers.first).to be_a(GasfreeSdk::Models::Provider)
      expect(providers.first.name).to eq("gasfree-provider")
      expect(providers.first.address).to eq("TKtWbdzEq5ss9vTS9kwRhBp5mXmBfBns3E")
      expect(providers.first.icon).to eq("https://example.com/icon.png")
      expect(providers.first.website).to eq("https://gasfree.io")
      expect(providers.first.config).to be_a(GasfreeSdk::Models::ProviderConfig)
      expect(providers.first.config.max_pending_transfer).to eq(1)
      expect(providers.first.config.min_deadline_duration).to eq(60)
      expect(providers.first.config.max_deadline_duration).to eq(3600)
      expect(providers.first.config.default_deadline_duration).to eq(180)
    end
  end

  describe "#address" do
    let(:account_address) { "0x1234567890123456789012345678901234567890" }

    it "returns GasFree account info" do
      stub_request(:get, "https://test.gasfree.io/api/v1/address/#{account_address}")
        .to_return(
          status: 200,
          body: {
            code: 200,
            data: {
              accountAddress: account_address,
              gasFreeAddress: "0x1234567890123456789012345678901234567890",
              active: true,
              nonce: 0,
              allowSubmit: true,
              assets: [
                {
                  tokenAddress: "0x1234567890123456789012345678901234567890",
                  tokenSymbol: "USDT",
                  activateFee: 1_000_000,
                  transferFee: 500_000,
                  decimal: 6,
                  frozen: 0
                }
              ]
            }
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      address = client.address(account_address)
      expect(address).to be_a(GasfreeSdk::Models::GasFreeAddress)
      expect(address.account_address).to eq(account_address)
    end
  end

  describe "#submit_transfer" do
    let(:request) do
      GasfreeSdk::Models::TransferRequest.new(
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
      )
    end

    it "submits a transfer request" do
      stub_request(:post, "https://test.gasfree.io/api/v1/gasfree/submit")
        .to_return(
          status: 200,
          body: {
            code: 200,
            data: {
              id: "test-transfer-id",
              created_at: 1_704_067_200_000, # milliseconds
              updated_at: 1_704_067_200_000, # milliseconds
              account_address: "0x1234567890123456789012345678901234567890",
              gas_free_address: "0x1234567890123456789012345678901234567890",
              provider_address: "0x1234567890123456789012345678901234567890",
              target_address: "0x1234567890123456789012345678901234567890",
              token_address: "0x1234567890123456789012345678901234567890",
              amount: "1000000",
              max_fee: "100000",
              signature: "0x1234567890123456789012345678901234567890123456789012345678901234",
              nonce: 0,
              expired_at: 1_704_067_380_000, # milliseconds
              state: "WAITING"
            }
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      response = client.submit_transfer(request)
      expect(response).to be_a(GasfreeSdk::Models::TransferResponse)
      expect(response.state).to eq("WAITING")
      expect(response.id).to eq("test-transfer-id")
    end
  end

  describe "#transfer_status" do
    let(:trace_id) { "test-trace-id" }

    it "returns transfer status" do
      stub_request(:get, "https://test.gasfree.io/api/v1/gasfree/#{trace_id}")
        .to_return(
          status: 200,
          body: {
            code: 200,
            data: {
              id: trace_id,
              created_at: 1_704_067_200_000, # milliseconds
              updated_at: 1_704_067_200_000, # milliseconds
              account_address: "0x1234567890123456789012345678901234567890",
              gas_free_address: "0x1234567890123456789012345678901234567890",
              provider_address: "0x1234567890123456789012345678901234567890",
              target_address: "0x1234567890123456789012345678901234567890",
              token_address: "0x1234567890123456789012345678901234567890",
              amount: "1000000",
              max_fee: "100000",
              signature: "0x1234567890123456789012345678901234567890123456789012345678901234",
              nonce: 0,
              expired_at: 1_704_067_380_000, # milliseconds
              state: "SUCCEED"
            }
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      status = client.transfer_status(trace_id)
      expect(status).to be_a(GasfreeSdk::Models::TransferResponse)
      expect(status.id).to eq(trace_id)
      expect(status.state).to eq("SUCCEED")
    end
  end

  describe "error handling" do
    context "with missing credentials" do
      before do
        GasfreeSdk.configure do |config|
          config.api_key = nil
          config.api_secret = nil
        end
      end

      it "raises ConfigurationError for nil credentials" do
        expect { client.tokens }.to raise_error(
          GasfreeSdk::ConfigurationError,
          /API key and secret must be configured and cannot be empty/
        )
      end
    end

    context "with empty string credentials" do
      it "raises ConfigurationError for empty API key" do
        GasfreeSdk.configure do |config|
          config.api_key = ""
          config.api_secret = "valid-secret"
        end

        expect { client.tokens }.to raise_error(
          GasfreeSdk::ConfigurationError,
          /API key and secret must be configured and cannot be empty/
        )
      end

      it "raises ConfigurationError for empty API secret" do
        GasfreeSdk.configure do |config|
          config.api_key = "valid-key"
          config.api_secret = ""
        end

        expect { client.tokens }.to raise_error(
          GasfreeSdk::ConfigurationError,
          /API key and secret must be configured and cannot be empty/
        )
      end

      it "raises ConfigurationError for both empty credentials" do
        GasfreeSdk.configure do |config|
          config.api_key = ""
          config.api_secret = ""
        end

        expect { client.tokens }.to raise_error(
          GasfreeSdk::ConfigurationError,
          /API key and secret must be configured and cannot be empty/
        )
      end

      it "raises ConfigurationError for whitespace-only credentials" do
        GasfreeSdk.configure do |config|
          config.api_key = "   "
          config.api_secret = "\t\n"
        end

        expect { client.tokens }.to raise_error(
          GasfreeSdk::ConfigurationError,
          /API key and secret must be configured and cannot be empty/
        )
      end
    end

    context "with API errors" do
      it "raises appropriate error for API failures" do
        stub_request(:get, "https://test.gasfree.io/api/v1/config/token/all")
          .to_return(
            status: 400,
            body: {
              code: "DEADLINE_EXCEEDED",
              reason: "DeadlineExceededException",
              message: "Request deadline exceeded"
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        expect { client.tokens }.to raise_error(GasfreeSdk::DeadlineExceededError)
      end
    end
  end
end
