# frozen_string_literal: true

require "gasfree_sdk"
require "vcr"
require "webmock/rspec"

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.default_cassette_options = { record: :new_episodes }

  # Allow HTTP connections when no cassette is active
  config.allow_http_connections_when_no_cassette = true

  # Filter out sensitive data
  config.filter_sensitive_data("<API_KEY>") { GasfreeSdk.config.api_key }
  config.filter_sensitive_data("<API_SECRET>") { GasfreeSdk.config.api_secret }
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:all) do
    GasfreeSdk.configure do |c|
      c.api_key = "test-key"
      c.api_secret = "test-secret"
      c.api_endpoint = "https://open-test.gasfree.io/nile/"
    end
  end

  config.after do
    GasfreeSdk.reset_client!
  end
end
