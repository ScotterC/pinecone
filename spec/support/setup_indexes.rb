require "dotenv/load"

Pinecone.configure do |config|
  config.api_key = ENV.fetch('PINECONE_API_KEY')
  config.environment = ENV.fetch('PINECONE_ENVIRONMENT')
end

valid_attributes = {
      "metric": "dotproduct",
      "name": "example-index",
      "dimension": 3,
}
client = Pinecone::Index.new
client.create(valid_attributes)