require "bundler/setup"
Bundler.setup
require "dotenv/load"
require "pinecone"

module IndexHelpers
  module_function

  def clear_indices
    ["serverless-index", "server-index"].each do |index_name|
      index = client.index(index_name)
      ["example-namespace", ""].each do |namespace|
        index.delete(delete_all: true, namespace: namespace)
      end
    end
  end

  def print_index_counts
    ["serverless-index", "server-index"].each do |index_name|
      index = client.index(index_name)
      puts "Index: #{index_name}"
      puts index.describe_index_stats
    end
  end

  def start_indices
    indices.each do |index_name|
      puts "Setting up #{index_name}"
      attributes = index_name.start_with?("serverless") ? serverless_valid_attributes : server_valid_attributes
      attributes[:name] = index_name
      response = client.create_index(attributes)
      puts response if response.code != 201
    end
  end

  def stop_indices
    (indices + ["test-index-serverless"]).each do |index_name|
      puts "Deleting #{index_name}"
      response = client.delete_index(index_name)
      puts response if response.code != 202
    end
  end

  def client
    @client ||= begin
      Pinecone.configure do |config|
        config.api_key = ENV.fetch("PINECONE_API_KEY")
        config.environment = ENV.fetch("PINECONE_ENVIRONMENT")
      end
      Pinecone::Client.new
    end
  end

  def serverless_valid_attributes
    {
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
  end

  def server_valid_attributes
    {
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
  end

  def indices
    @indices ||= ["serverless-index", "server-index"]
  end
end
