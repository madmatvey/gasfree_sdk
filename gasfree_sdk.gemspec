# frozen_string_literal: true

require_relative "lib/gasfree_sdk/version"

Gem::Specification.new do |spec|
  spec.name = "gasfree_sdk"
  spec.version = GasfreeSdk::VERSION
  spec.authors = ["madmatvey"]
  spec.email = ["potehin@gmail.com"]

  spec.summary = "Ruby SDK for GasFree.io - TRC-20/ERC-20 gasless transfer solution"
  spec.description = "GasFree SDK provides a Ruby interface for interacting with GasFree.io API, " \
                     "enabling gasless transfers of TRC-20/ERC-20 tokens. It supports address " \
                     "generation, transaction signing, and other operations described in the " \
                     "GasFree API specification."
  spec.homepage = "https://github.com/madmatvey/gasfree_sdk"
  spec.license = "LGPL-3.0"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "dry-configurable", "~> 1.1"
  spec.add_dependency "dry-struct", "~> 1.6"
  spec.add_dependency "dry-types", "~> 1.7"
  spec.add_dependency "dry-validation", "~> 1.10"
  spec.add_dependency "eth", "~> 0.5"
  spec.add_dependency "faraday", "~> 2.9"
  spec.add_dependency "faraday-retry", "~> 2.2"
  spec.add_dependency "rbsecp256k1", "~> 6.0"

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rubocop", "~> 1.60"
  spec.add_development_dependency "rubocop-rake", "~> 0.6"
  spec.add_development_dependency "rubocop-rspec", "~> 2.26"
  spec.add_development_dependency "vcr", "~> 6.2"
  spec.add_development_dependency "webmock", "~> 3.19"
  spec.add_development_dependency "yard", "~> 0.9"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
