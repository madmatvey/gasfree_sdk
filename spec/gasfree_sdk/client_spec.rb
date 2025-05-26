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
      # Mock the HTTP response
      stub_request(:get, "https://test.gasfree.io/api/v1/config/token/all")
        .to_return(
          status: 200,
          body: {
            code: 200,
            data: {
              tokens: [
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
              ]
            }
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      tokens = client.tokens
      expect(tokens).to be_an(Array)
      expect(tokens.first).to be_a(GasfreeSdk::Models::Token)
      expect(tokens.first.symbol).to eq("USDT")
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
                  address: "0x1234567890123456789012345678901234567890",
                  name: "Provider-1",
                  icon: "",
                  website: "",
                  config: {
                    max_pending_transfer: 1,
                    min_deadline_duration: 60,
                    max_deadline_duration: 600,
                    default_deadline_duration: 180
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
      expect(providers.first.name).to eq("Provider-1")
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
              account_address: account_address,
              gas_free_address: "0x1234567890123456789012345678901234567890",
              active: true,
              nonce: 0,
              allow_submit: true,
              assets: [
                {
                  token_address: "0x1234567890123456789012345678901234567890",
                  token_symbol: "USDT",
                  activate_fee: "1000000",
                  transfer_fee: "500000",
                  decimal: 6,
                  frozen: "0"
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

      it "raises AuthenticationError" do
        expect { client.tokens }.to raise_error(GasfreeSdk::AuthenticationError)
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
