# frozen_string_literal: true

require "bundler/setup"
Bundler.setup
require "dotenv/load"
require "pinecone"
require "debug"
require_relative "support/local_container_helpers"

RSpec.configure do |c|
  c.include LocalContainerHelpers

  c.before(:all) do
    Pinecone.configure do |config|
      config.api_key = ENV.fetch("PINECONE_API_KEY")
      config.silence_deprecation_warnings = true # Silence warnings in tests
    end
  end
end
