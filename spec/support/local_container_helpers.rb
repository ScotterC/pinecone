# frozen_string_literal: true

require "net/http"
require "timeout"

module LocalContainerHelpers
  DATABASE_HOST = "localhost:5080"
  DENSE_HOST = "localhost:5081"
  SPARSE_HOST = "localhost:5082"
  DATABASE_URL = "http://#{DATABASE_HOST}".freeze
  DENSE_URL = "http://#{DENSE_HOST}".freeze
  SPARSE_URL = "http://#{SPARSE_HOST}".freeze

  module_function

  def database_available?
    uri = URI("#{DATABASE_URL}/indexes")
    response = Net::HTTP.get_response(uri)
    response.code == "200"
  rescue
    false
  end

  def dense_container_available?
    uri = URI("#{DENSE_URL}/vectors/list")
    response = Net::HTTP.get_response(uri)
    response.code == "200"
  rescue
    false
  end

  def sparse_container_available?
    uri = URI("#{SPARSE_URL}/vectors/list")
    response = Net::HTTP.get_response(uri)
    response.code == "200"
  rescue
    false
  end

  def all_containers_available?
    database_available? && dense_container_available? && sparse_container_available?
  end

  def wait_for_containers(timeout: 30)
    Timeout.timeout(timeout) do
      loop do
        break if all_containers_available?

        sleep 0.5
      end
    end
  rescue Timeout::Error
    available = []
    available << "database (#{DATABASE_HOST})" if database_available?
    available << "dense (#{DENSE_HOST})" if dense_container_available?
    available << "sparse (#{SPARSE_HOST})" if sparse_container_available?

    raise "Local Pinecone containers not fully available. Available: #{available.join(", ")}. Please start with: docker-compose -f docker-compose.test.yml up -d"
  end

  def local_client(api_key: "dummy-key")
    Pinecone::Client.new.tap do |_client|
      # Configure for local testing
      Pinecone.configure do |config|
        config.api_key = api_key
        config.silence_deprecation_warnings = true
      end
    end
  end

  def dense_index
    local_client.index(host: DENSE_HOST)
  end

  def sparse_index
    local_client.index(host: SPARSE_HOST)
  end

  def database_client
    @database_client ||= begin
      Pinecone.configure do |config|
        config.api_key = "dummy-key"
        config.silence_deprecation_warnings = true
      end

      # Create a client that can talk to the database emulator for control plane operations
      client = Pinecone::Client.new
      # Override the base_uri for control plane operations
      Pinecone::Index.any_instance.define_singleton_method(:initialize) do
        self.class.base_uri "http://#{DATABASE_HOST}"
        @headers = {
          "Content-Type" => "application/json",
          "Accept" => "application/json",
          "Api-Key" => "dummy-key"
        }
      end
      client
    end
  end

  def cleanup_containers
    [dense_index, sparse_index].each do |index|
      index.delete(delete_all: true)
    rescue => e
      # Ignore cleanup errors
      puts "Warning: Failed to cleanup container: #{e.message}" if ENV["DEBUG"]
    end
  end
end
