# Usage
#
# Creates an example test index
# ruby spec/support/setup.rb start
#
# Deletes test index
# ruby spec/support/setup.rb stop 

require 'bundler/setup'
Bundler.setup
require "dotenv/load"
require "pinecone"

Pinecone.configure do |config|
  config.api_key = ENV.fetch('PINECONE_API_KEY')
  config.environment = ENV.fetch('PINECONE_ENVIRONMENT')
end

client = Pinecone::Index.new
indices = ["example-index-1", "example-index-2"]
valid_attributes = {
  "metric": "dotproduct",
  "name": "example-index-1",
  "dimension": 3,
}

# Check if an argument was provided
if ARGV.length == 1
  case ARGV[0].downcase
  when 'start'
    indices.each do |index_name|
      puts "Setting up #{index_name}"
      valid_attributes["name"] = index_name
      client.create(valid_attributes)
    end
  when 'stop'
    indices.each do |index_name|
      puts "Deleting #{index_name}"
      client.delete(index_name)
    end
  else
    puts "Invalid argument. Use 'start' to create the index or 'stop' to delete the index."
  end
else
  puts "Please provide one argument: 'start' to create the index or 'stop' to delete the index."
end