# Usage
#
# Creates an example test index
# ruby spec/support/setup.rb start
#
# Deletes test index
# ruby spec/support/setup.rb stop

require "bundler/setup"
Bundler.setup
require "dotenv/load"
require "pinecone"

Pinecone.configure do |config|
  config.api_key = ENV.fetch("PINECONE_API_KEY")
  config.environment = ENV.fetch("PINECONE_ENVIRONMENT")
end

client = Pinecone::Index.new
indices = ["serverless-index", "server-index"]
serverless_valid_attributes = {
  metric: "dotproduct",
  name: "serverless-index",
  dimension: 3,
  spec: {
    serverless: {
      cloud: "aws",
      region: "us-east-1"
    }
  }
}

server_valid_attributes = {
  metric: "dotproduct",
  name: "server-index",
  dimension: 3,
  spec: {
    pod: {
      environment: ENV.fetch("PINECONE_ENVIRONMENT"),
      pod_type: "p1.x1",
      pods: 1
    }
  }
}

# Check if an argument was provided
if ARGV.length == 1
  case ARGV[0].downcase
  when "start"
    indices.each do |index_name|
      puts "Setting up #{index_name}"
      attributes = index_name.start_with?("serverless") ? serverless_valid_attributes : server_valid_attributes
      attributes[:name] = index_name
      response = client.create(attributes)
      puts response if response.code != 201
    end
  when "stop"
    indices << "test-index-serverless"
    indices.each do |index_name|
      puts "Deleting #{index_name}"
      response = client.delete(index_name)
      puts response if response.code != 202
    end
  else
    puts "Invalid argument. Use 'start' to create the index or 'stop' to delete the index."
  end
else
  puts "Please provide one argument: 'start' to create the index or 'stop' to delete the index."
end
