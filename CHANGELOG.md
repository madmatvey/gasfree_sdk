# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- TRON address format support alongside existing Ethereum address support
- Automatic data transformation between API camelCase and model snake_case formats
- Enhanced address validation for both Ethereum (`0x...`) and TRON (`T...`) formats
- Comprehensive error handling for address format mismatches
- Support for TRON testnet endpoints (e.g., `https://open-test.gasfree.io/nile/`)
- Troubleshooting section in documentation with common issues and solutions

### Fixed
- **BREAKING**: Fixed TRON address compatibility issues when using TRON endpoints
- Fixed data type validation errors for API responses with integer values
- Fixed asset data transformation to handle both string and integer values from API
- Corrected address data transformation to match real API response format
- Updated test fixtures to match actual API response structure

### Changed
- Enhanced client to automatically transform API response data to match model expectations
- Updated examples to demonstrate TRON address usage for TRON testnet
- Improved documentation with TRON-specific examples and usage patterns
- Added mock signature generation for demo purposes in examples

### Technical Details
- Added `transform_address_data` and `transform_asset_data` methods to handle API response transformation
- Updated type coercion to handle mixed data types from API responses
- Enhanced address validation regex to support both Ethereum and TRON formats
- Fixed test mocks to use camelCase format matching real API responses

## [0.1.3] - Pre Release

### Added
- Initial SDK implementation with support for GasFree.io API
- Token, Provider, and Transfer management
- Ethereum address support
- Comprehensive test coverage
- RSpec testing framework integration
- Dry-rb validation and type checking

## [0.1.2] - 2025-05-28

### Fixed
- Fixed Service Providers API data mapping from camelCase to snake_case
- Added proper transformation for provider configuration fields (maxPendingTransfer -> max_pending_transfer, etc.)
- Updated tests to use correct API response format for providers

### Enhanced
- Improved documentation for Service Providers with detailed configuration constraints
- Added comprehensive test coverage for provider field mapping

## [0.1.1] - 2025-05-26

### Added
- Support for different API endpoints (mainnet, testnet, custom)
- Improved URL path handling for API requests

## [0.1.0] - 2025-05-26

- Initial release
