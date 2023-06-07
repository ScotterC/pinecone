require 'bundler/setup'
Bundler.setup
require "dotenv/load"
require "pinecone"
require "vcr"
require 'debug'

class PineconeContext
  attr_accessor :vector

  def index_name
    vector&.index_name
  end
end

pinecone_context = PineconeContext.new

VCR.configure do |c|
  c.hook_into :webmock
  c.cassette_library_dir = "spec/cassettes"
  c.configure_rspec_metadata!
  c.default_cassette_options = { record: ENV["NO_VCR"] == "true" ? :all : :new_episodes}
  c.filter_sensitive_data("<PINECONE_API_KEY>") { Pinecone.configuration.api_key }
  c.filter_sensitive_data("<PINECONE_ENVIRONMENT>") { Pinecone.configuration.environment }
  c.filter_sensitive_data("<PINECONE_INDEX_NAME_1>") do |interaction|
    if interaction.request.uri.include?(ENV['TEST_INDEX_NAME_1'])
      interaction.request.uri.gsub!(ENV['TEST_INDEX_NAME_1'], "<PINECONE_INDEX_NAME_1>")
    end
  end
  c.filter_sensitive_data("<PINECONE_INDEX_NAME_2>") do |interaction|
    if interaction.request.uri.include?(ENV['TEST_INDEX_NAME_2'])
      interaction.request.uri.gsub!(ENV['TEST_INDEX_NAME_2'], "<PINECONE_INDEX_NAME_2>")
    end
  end
  c.before_playback do |interaction, _|
    # Replace placeholders with actual index names for playback
    if interaction.request.uri.include?("<PINECONE_INDEX_NAME_1>")
      interaction.filter!("<PINECONE_INDEX_NAME_1>", ENV['TEST_INDEX_NAME_1'])
    end

    if interaction.request.uri.include?("<PINECONE_INDEX_NAME_2>")
      interaction.filter!("<PINECONE_INDEX_NAME_2>", ENV['TEST_INDEX_NAME_2'])
    end
  end
end

RSpec.configure do |c|
  c.before(:all) do
    Pinecone.configure do |config|
      config.api_key = ENV.fetch('PINECONE_API_KEY')
      config.environment = ENV.fetch('PINECONE_ENVIRONMENT')
    end
  end
end

# Note: Crazy GPT generated Regex. This could be more reliable to make a method in lib to extract index name
# https://{index_name-project_id}.svc.{environment}.pinecone.io
# "https://controller.us-east1-gcp.pinecone.io/databases/{index_name}}"
def extract_index_name_from_uri(uri)
  uri.match(%r{https://(?:([^/]+)-[^/]+\.svc\.[^/]+\.pinecone\.io)|(?:controller[^/]+/databases/([^/]+))})[1,2].compact.first
end