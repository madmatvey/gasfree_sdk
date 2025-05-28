# frozen_string_literal: true

RSpec.describe GasfreeSdk::TronEIP712Signer do
  let(:private_key) { "09234f48ce1b0b70d4a553a59bdd542aa51bfa8e1ef6dd9e1fcc1f041d6bfa2d" }
  let(:user_address) { "TYRhsi1fkke2tjdVW9XGYLjf8TgbbutEgY" }
  let(:message_data) do
    {
      token: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t",
      serviceProvider: "TGzz8gjYiYRqpfmDwnLxfgPuLVNmpCswVp",
      user: user_address,
      receiver: "TW1dWXfta5ygVN298JBN2UPhaSAUzo2owZ",
      value: "3000000",
      maxFee: "2000000",
      deadline: "1749371692",
      version: 1,
      nonce: 0
    }
  end

  describe ".sign_typed_data_testnet" do
    it "generates a valid signature for testnet" do
      signature = described_class.sign_typed_data_testnet(private_key, message_data)

      expect(signature).to be_a(String)
      expect(signature.length).to eq(130) # 65 bytes * 2 hex chars
      expect(signature).to match(/\A[0-9a-f]+\z/i) # Only hex characters
    end

    it "generates consistent signatures for the same input" do
      sig1 = described_class.sign_typed_data_testnet(private_key, message_data)
      sig2 = described_class.sign_typed_data_testnet(private_key, message_data)

      expect(sig1).to eq(sig2)
    end
  end

  describe ".sign_typed_data_mainnet" do
    it "generates a valid signature for mainnet" do
      signature = described_class.sign_typed_data_mainnet(private_key, message_data)

      expect(signature).to be_a(String)
      expect(signature.length).to eq(130)
      expect(signature).to match(/\A[0-9a-f]+\z/i)
    end

    it "generates different signatures for testnet vs mainnet" do
      testnet_sig = described_class.sign_typed_data_testnet(private_key, message_data)
      mainnet_sig = described_class.sign_typed_data_mainnet(private_key, message_data)

      expect(testnet_sig).not_to eq(mainnet_sig)
    end
  end

  describe ".sign_typed_data" do
    it "accepts custom domain parameters" do
      custom_domain = {
        name: "CustomController",
        version: "V2.0.0",
        chainId: 123_456,
        verifyingContract: "THQGuFzL87ZqhxkgqYEryRAd7gqFqL5rdc"
      }

      signature = described_class.sign_typed_data(
        private_key,
        message_data,
        domain: custom_domain
      )

      expect(signature).to be_a(String)
      expect(signature.length).to eq(130)
    end
  end

  describe "domain constants" do
    it "has correct testnet domain" do
      domain = described_class::DOMAIN_TESTNET

      expect(domain[:name]).to eq("GasFreeController")
      expect(domain[:version]).to eq("V1.0.0")
      expect(domain[:chainId]).to eq(3_448_148_188)
      expect(domain[:verifyingContract]).to eq("THQGuFzL87ZqhxkgqYEryRAd7gqFqL5rdc")
    end

    it "has correct mainnet domain" do
      domain = described_class::DOMAIN_MAINNET

      expect(domain[:name]).to eq("GasFreeController")
      expect(domain[:version]).to eq("V1.0.0")
      expect(domain[:chainId]).to eq(728_126_428)
      expect(domain[:verifyingContract]).to eq("TFFAMQLZybALaLb4uxHA9RBE7pxhUAjF3U")
    end
  end

  describe ".keccac256" do
    it "generates correct hash" do
      data = "Hello, TRON!"
      hash = described_class.keccac256(data)

      expect(hash).to be_a(String)
      expect(hash.length).to eq(32) # 32 bytes
    end

    it "generates consistent hashes" do
      data = "test data"
      hash1 = described_class.keccac256(data)
      hash2 = described_class.keccac256(data)

      expect(hash1).to eq(hash2)
    end
  end

  describe ".keccac256_hex" do
    it "generates hex encoded hash" do
      data = "Hello, TRON!"
      hex_hash = described_class.keccac256_hex(data)

      expect(hex_hash).to be_a(String)
      expect(hex_hash.length).to eq(64) # 32 bytes * 2 hex chars
      expect(hex_hash).to match(/\A[0-9a-f]+\z/i)
    end
  end

  describe ".encode_type" do
    it "encodes PermitTransfer type correctly" do
      encoded = described_class.encode_type(:PermitTransfer)

      expect(encoded).to include("PermitTransfer(")
      expect(encoded).to include("address token")
      expect(encoded).to include("address serviceProvider")
      expect(encoded).to include("uint256 value")
    end
  end

  describe "error handling" do
    it "raises error for missing required fields" do
      incomplete_data = message_data.dup
      incomplete_data.delete(:token)

      expect do
        described_class.sign_typed_data_testnet(private_key, incomplete_data)
      end.to raise_error(/Missing value for field 'token'/)
    end

    it "raises error for invalid private key" do
      invalid_key = "invalid_key"

      expect do
        described_class.sign_typed_data_testnet(invalid_key, message_data)
      end.to raise_error(/private key data must be 32 bytes in length/)
    end
  end
end
