## [Unreleased]

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
