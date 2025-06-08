# frozen_string_literal: true

require "rbsecp256k1"

module GasfreeSdk
  # EIP-712 Signature implementation for TRON GasFree
  # This module provides functionality to sign EIP-712 structured data
  # according to TRON's implementation of the standard (TIP-712)
  class TronEIP712Signer
    # TRON Nile testnet parameters from GasFree documentation
    DOMAIN_TESTNET = {
      name: "GasFreeController",
      version: "V1.0.0",
      chainId: 3_448_148_188, # TRON Nile testnet - according to GasFree documentation
      verifyingContract: "THQGuFzL87ZqhxkgqYEryRAd7gqFqL5rdc"
    }.freeze

    # TRON Mainnet parameters
    DOMAIN_MAINNET = {
      name: "GasFreeController",
      version: "V1.0.0",
      chainId: 728_126_428, # TRON Mainnet - according to GasFree documentation
      verifyingContract: "TFFAMQLZybALaLb4uxHA9RBE7pxhUAjF3U"
    }.freeze

    # EIP-712 type definitions for PermitTransfer
    TYPES = {
      PermitTransfer: [
        { name: "token", type: "address" },
        { name: "serviceProvider", type: "address" },
        { name: "user", type: "address" },
        { name: "receiver", type: "address" },
        { name: "value", type: "uint256" },
        { name: "maxFee", type: "uint256" },
        { name: "deadline", type: "uint256" },
        { name: "version", type: "uint256" },
        { name: "nonce", type: "uint256" }
      ]
    }.freeze

    class << self
      # Generate Keccak256 hash of data
      # @param data [String] Data to hash
      # @return [String] Binary hash
      def keccac256(data)
        GasfreeSdk::Crypto::Keccak256.new.digest(data.to_s)
      end

      # Generate Keccac256 hash of data as hex string
      # @param data [String] Data to hash
      # @return [String] Hex encoded hash
      def keccac256_hex(data)
        GasfreeSdk::Crypto::Keccak256.new.hexdigest(data.to_s)
      end

      # Encode EIP-712 type definition
      # @param primary_type [Symbol] Primary type name
      # @param types [Hash] Type definitions
      # @return [String] Encoded type string
      def encode_type(primary_type, types = TYPES)
        deps = find_dependencies(primary_type, types)
        deps.delete(primary_type)
        deps = [primary_type] + deps.sort

        deps.map do |type|
          "#{type}(#{types[type].map { |field| "#{field[:type]} #{field[:name]}" }.join(",")})"
        end.join
      end

      # Find type dependencies recursively
      # @param primary_type [Symbol] Primary type name
      # @param types [Hash] Type definitions
      # @param found [Set] Already found dependencies
      # @return [Set] Set of dependencies
      def find_dependencies(primary_type, types, found = Set.new)
        return found if found.include?(primary_type)
        return found unless types[primary_type]

        found << primary_type
        types[primary_type].each do |field|
          dep = field[:type].gsub(/\[\]$/, "")
          find_dependencies(dep, types, found) if types[dep] && !found.include?(dep)
        end
        found
      end

      # Encode structured data according to EIP-712
      # @param primary_type [Symbol] Primary type name
      # @param data [Hash] Data to encode
      # @param types [Hash] Type definitions
      # @return [String] Encoded data
      def encode_data(primary_type, data, types = TYPES) # rubocop:disable Metrics/AbcSize
        encoded_types = encode_type(primary_type, types)
        type_hash = keccac256(encoded_types)

        encoded_values = types[primary_type].map do |field|
          field_name = field[:name]
          # Try multiple key formats: original, symbol, snake_case conversion
          value = data[field_name] ||
                  data[field_name.to_sym] ||
                  data[snake_case_to_camel_case(field_name)] ||
                  data[snake_case_to_camel_case(field_name).to_sym] ||
                  data[camel_case_to_snake_case(field_name)] ||
                  data[camel_case_to_snake_case(field_name).to_sym]

          raise "Missing value for field '#{field_name}' in data: #{data.keys}" if value.nil?

          encode_value(field[:type], value, types)
        end.join

        type_hash + [encoded_values].pack("H*")
      end

      # Convert snake_case to camelCase
      # @param str [String] String to convert
      # @return [String] Converted string
      def snake_case_to_camel_case(str)
        str.to_s.split("_").map.with_index { |word, i| i.zero? ? word : word.capitalize }.join
      end

      # Convert camelCase to snake_case
      # @param str [String] String to convert
      # @return [String] Converted string
      def camel_case_to_snake_case(str)
        str.to_s.gsub(/([A-Z])/, '_\1').downcase.sub(/^_/, "")
      end

      # Encode a single value according to its type
      # @param type [String] Value type
      # @param value [Object] Value to encode
      # @param types [Hash] Type definitions
      # @return [String] Encoded value as hex string
      def encode_value(type, value, types = TYPES) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        case type
        when "string"
          keccac256_hex(value.to_s)
        when "uint256"
          # Convert to 32-byte hex string - handle both string and integer input
          # For string values (like deadline), convert to integer first
          int_value = value.to_i
          int_value.to_s(16).rjust(64, "0")
        when "address"
          # TRON addresses need to be converted to hex format according to TIP-712
          # TIP-712: "address: need to remove TRON unique prefix(0x41) and encoded as uint160"
          addr_bytes = GasfreeSdk::Base58.base58_to_binary(value.to_s)
          # Take the middle 20 bytes (skip version byte 0x41 and checksum)
          hex_addr = addr_bytes[1, 20].unpack1("H*")
          hex_addr.rjust(64, "0")
        when /\[\]$/
          # Array type
          item_type = type.gsub(/\[\]$/, "")
          array_items = value.map { |item| encode_value(item_type, item, types) }
          keccac256_hex(array_items.join)
        else
          raise "Unknown type: #{type}" unless types[type.to_sym]

          # Custom type
          encoded_data = encode_data(type.to_sym, value, types)
          keccac256_hex(encoded_data)
        end
      end

      # Hash structured data
      # @param primary_type [Symbol] Primary type name
      # @param data [Hash] Data to hash
      # @param types [Hash] Type definitions
      # @return [String] Hash as binary string
      def hash_struct(primary_type, data, types = TYPES)
        encoded_data = encode_data(primary_type, data, types)
        keccac256(encoded_data)
      end

      # Hash domain separator
      # @param domain [Hash] Domain parameters
      # @return [String] Domain hash as binary string
      def hash_domain(domain = DOMAIN_TESTNET)
        # Create EIP712Domain type manually since it's not in TYPES
        eip712_domain_type = [
          { name: "name", type: "string" },
          { name: "version", type: "string" },
          { name: "chainId", type: "uint256" },
          { name: "verifyingContract", type: "address" }
        ]

        # Temporarily add to types for encoding
        temp_types = TYPES.merge({ EIP712Domain: eip712_domain_type })
        hash_struct(:EIP712Domain, domain, temp_types)
      end

      # Sign typed data according to EIP-712
      # @param private_key_hex [String] Private key as hex string
      # @param message_data [Hash] Message data to sign
      # @param domain [Hash] Domain parameters (defaults to testnet)
      # @param use_ethereum_v [Boolean] Whether to use Ethereum-style V value (recovery_id + 27)
      # @return [String] Signature as hex string
      def sign_typed_data(private_key_hex, message_data, domain: DOMAIN_TESTNET, use_ethereum_v: true) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        # EIP-712 signature implementation for TRON GasFree
        # This implementation has been verified to be mathematically correct
        # through local signature verification

        # Create the EIP-712 hash
        domain_separator = hash_domain(domain)
        message_hash = hash_struct(:PermitTransfer, message_data)

        # Create the final hash according to EIP-712
        prefix = "\x19\x01"
        digest_input = prefix + domain_separator + message_hash
        digest = keccac256(digest_input)

        # Ensure digest is exactly 32 bytes
        raise "Hash is #{digest.length} bytes, expected 32" if digest.length != 32

        # Sign with secp256k1
        context = Secp256k1::Context.new
        private_key = [private_key_hex].pack("H*")
        key_pair = context.key_pair_from_private_key(private_key)

        # Create recoverable signature
        compact, recovery_id = context.sign_recoverable(
          key_pair.private_key,
          digest
        ).compact

        # Format signature as r + s + v
        signature_bytes = compact.bytes

        v_value = if use_ethereum_v
                    # TRON/Ethereum style V (recovery_id + 27)
                    recovery_id + 27
                  else
                    # Standard format: just recovery_id
                    recovery_id
                  end

        signature_bytes << v_value

        # Convert to hex string without 0x prefix
        signature_bytes.pack("C*").unpack1("H*")
      end

      # Sign for mainnet
      # @param private_key_hex [String] Private key as hex string
      # @param message_data [Hash] Message data to sign
      # @param use_ethereum_v [Boolean] Whether to use Ethereum-style V value
      # @return [String] Signature as hex string
      def sign_typed_data_mainnet(private_key_hex, message_data, use_ethereum_v: true)
        sign_typed_data(private_key_hex, message_data, domain: DOMAIN_MAINNET, use_ethereum_v: use_ethereum_v)
      end

      # Sign for testnet (alias for default behavior)
      # @param private_key_hex [String] Private key as hex string
      # @param message_data [Hash] Message data to sign
      # @param use_ethereum_v [Boolean] Whether to use Ethereum-style V value
      # @return [String] Signature as hex string
      def sign_typed_data_testnet(private_key_hex, message_data, use_ethereum_v: true)
        sign_typed_data(private_key_hex, message_data, domain: DOMAIN_TESTNET, use_ethereum_v: use_ethereum_v)
      end
    end
  end
end
