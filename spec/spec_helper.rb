require "bundler/setup"
Bundler.setup
require "dotenv/load"
require "pinecone"
require "vcr"
require "debug"

VCR.configure do |c|
  c.hook_into :webmock
  c.cassette_library_dir = "spec/cassettes"
  c.configure_rspec_metadata!
  c.default_cassette_options = {record: (ENV["NO_VCR"] == "true") ? :all : :new_episodes}
  c.filter_sensitive_data("<PINECONE_API_KEY>") { Pinecone.configuration.api_key }
  c.filter_sensitive_data("<PINECONE_ENVIRONMENT>") { Pinecone.configuration.environment }
end

RSpec.configure do |c|
  c.before(:all) do
    Pinecone.configure do |config|
      config.api_key = ENV.fetch("PINECONE_API_KEY")
      config.environment = ENV.fetch("PINECONE_ENVIRONMENT")
    end
  end
end
