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
require 'fileutils'

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

def write_index_to_env(index_name, env_var_name)
  open('.env', 'a') do |f|
    f.puts unless File.zero?('.env')
    f.puts "#{env_var_name}=#{index_name}"
  end
end

def remove_index_from_env(env_var_name)
  return unless File.exist?('.env') # Skip if .env does not exist
  FileUtils.cp('.env', '.env.bak')
  open('.env.bak', 'r') do |source|
    open('.env', 'w') do |target|
      source.each_line do |line|
        target.write(line) unless line.include?("#{env_var_name}=")
      end
    end
  end
  FileUtils.rm('.env.bak')
end

# Check if an argument was provided
if ARGV.length == 1
  case ARGV[0].downcase
  when 'start'
    indices.each_with_index do |index_name, index|
      puts "Setting up #{index_name}"
      valid_attributes["name"] = index_name
      client.create(valid_attributes)
      write_index_to_env(index_name, "TEST_INDEX_NAME_#{index + 1}")
    end
  when 'stop'
    indices.each_with_index do |index_name, index|
      puts "Deleting #{index_name}"
      client.delete(index_name)
      remove_index_from_env("TEST_INDEX_NAME_#{index + 1}")
    end
  else
    puts "Invalid argument. Use 'start' to create the index or 'stop' to delete the index."
  end
else
  puts "Please provide one argument: 'start' to create the index or 'stop' to delete the index."
end