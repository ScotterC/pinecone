require "bundler/setup"
Bundler.setup
require "dotenv/load"
require "pinecone"
require "vcr"
require "debug"
require_relative "support/index_helpers"

VCR.configure do |c|
  c.hook_into :webmock
  c.cassette_library_dir = "spec/cassettes"
  c.configure_rspec_metadata!
  c.default_cassette_options = {
    record: (ENV["NO_VCR"] == "true") ? :all : :new_episodes,
    clean_outdated_http_interactions: true
  }
  c.filter_sensitive_data("<PINECONE_API_KEY>") { Pinecone.configuration.api_key }
  c.filter_sensitive_data("<PINECONE_ENVIRONMENT>") { Pinecone.configuration.environment }
end

RSpec.configure do |c|
  c.include IndexHelpers
  
  c.before(:all) do
    Pinecone.configure do |config|
      config.api_key = ENV.fetch("PINECONE_API_KEY")
      config.environment = ENV.fetch("PINECONE_ENVIRONMENT")
      config.silence_deprecation_warnings = true  # Silence warnings in tests
    end
  end

  # Clear Test Indices after each test
  # Current Testing Caveats
  # Only use indexes with names: ["serverless-index", "server-index"]
  # Only use namespaces with names: ["example-namespace", ""]
  c.after(:each) do
    VCR.use_cassette("clear_index") do
      IndexHelpers.clear_indices
    end
  end
end
