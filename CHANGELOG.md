# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-01-XX

### Added
- **LogSanitizer**: Automatic masking of sensitive data in debug logs
  - Recursive sanitization of HTTP request/response data
  - Protection of private keys, tokens, signatures, and other sensitive fields
  - Customizable sensitive field detection and masking patterns
  - Support for nested data structures (Hash, Array, primitive types)

- **LogSanitizerMiddleware**: Faraday middleware for automatic log sanitization
  - Integrated with existing debug logging (`DEBUG_GASFREE_SDK=1`)
  - Masks sensitive data before logging to prevent security leaks
  - Handles both request and response data sanitization

### Security
- **Automatic Data Protection**: Sensitive fields are now automatically masked in debug logs
  - Headers: `Authorization`, `Api-Key`, `X-Api-Key`, etc.
  - Body fields: `private_key`, `api_secret`, `signature`, `token`, etc.
  - Prevents accidental exposure of credentials in log files

### Features
- `GasfreeSdk::LogSanitizer` - Universal data sanitization utility
- `GasfreeSdk::LogSanitizerMiddleware` - Faraday middleware for automatic sanitization
- Environment variable `DEBUG_GASFREE_SDK=1` now includes automatic data protection

### Documentation
- Added "Debugging and Logging" section to README.md
- Documented automatic sensitive data protection features
- Added usage examples for debug logging

## [1.0.0] - 2025-06-08

### Added
- **TronEIP712Signer Module**: Complete EIP-712 signature implementation for TRON GasFree transfers
  - Full EIP-712 structured data signing according to TIP-712 specifications
  - Support for both TRON Mainnet and Testnet (Nile) networks
  - Built-in Keccak256 cryptographic hashing implementation
  - Base58 encoding/decoding utilities for TRON addresses
  - Flexible data key handling (camelCase, snake_case conversion)
  - Pre-configured domain constants for GasFree contracts
  - Comprehensive test coverage with RSpec

- **Core GasFree SDK functionality**
  - API client for GasFree.io with support for different endpoints (mainnet, testnet, custom)
  - Support for tokens, providers, and transfer operations
  - Comprehensive error handling and validation
  - Ethereum and TRON address support
  - RSpec test suite with comprehensive coverage
  - Dry-rb validation and type checking

### Features
- `GasfreeSdk::TronEIP712Signer.sign_typed_data_testnet()` - Sign for TRON Testnet
- `GasfreeSdk::TronEIP712Signer.sign_typed_data_mainnet()` - Sign for TRON Mainnet
- `GasfreeSdk::TronEIP712Signer.sign_typed_data()` - Generic signing with custom domains
- `GasfreeSdk::Crypto::Keccak256` - Pure Ruby Keccak256 implementation
- `GasfreeSdk::Base58` - TRON address encoding/decoding utilities
- Token, Provider, and Transfer management APIs
- Service Providers API with proper data mapping from camelCase to snake_case
- Improved URL path handling for API requests

### Dependencies
- Added `rbsecp256k1` (~> 6.0) for secp256k1 cryptographic operations

### Examples
- `examples/simple_usage_example.rb` - Basic TronEIP712Signer usage demonstration
- `examples/test_tron_signer.rb` - Comprehensive module testing script
- Updated `examples/test_with_real_data_prod.rb` to use the new module

### Documentation
- Updated README.md with comprehensive TronEIP712Signer documentation
- Added usage examples and API reference
- Documented all cryptographic operations and utilities
- Improved documentation for Service Providers with detailed configuration constraints

### Fixed
- Fixed Service Providers API data mapping from camelCase to snake_case
- Added proper transformation for provider configuration fields (maxPendingTransfer -> max_pending_transfer, etc.)
- Updated tests to use correct API response format for providers

### Enhanced
- Comprehensive test coverage for provider field mapping
- RSpec testing framework integration
- Improved error handling and validation throughout the SDK
