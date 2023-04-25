require "dotenv/load"

Pinecone.configure do |config|
  config.api_key = ENV.fetch('PINECONE_API_KEY')
  config.environment = ENV.fetch('PINECONE_ENVIRONMENT')
end

client = Pinecone::Index.new
client.delete("example-index")