require "httparty"

require "pinecone/client"
require "pinecone/index"
require "pinecone/vector"
require "pinecone/version"

module Pinecone
  class ConfigurationError < StandardError; end
  class Configuration
    attr_writer :api_key, :base_uri, :environment

    def initialize
      @api_key     = nil
      @environment = nil
      @base_uri    = nil
    end

    def api_key
      return @api_key if @api_key

      raise ConfigurationError, "Pinecone API key not set"
    end

    def base_uri
      return @base_uri if @base_uri

      raise ConfigurationError, "Pinecone domain not set"
    end

    def environment
      return @environment if @environment

      raise ConfigurationError, "Pinecone environment not set"
    end
  end

  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Pinecone::Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end

# Vector Operations

# # GET Describe Index Stats
# https://index_name-project_id.svc.environment.pinecone.io/describe_index_stats

# # POST Describe Index Stats
# https://index_name-project_id.svc.environment.pinecone.io/describe_index_stats

# # DELETE Delete Vectors
# https://index_name-project_id.svc.environment.pinecone.io/vectors/delete

# # POST Delete Vectors
# # The Delete operation deletes vectors, by id, from a single namespace.
# https://index_name-project_id.svc.environment.pinecone.io/vectors/delete

# # GET Fetch
# # The Fetch operation looks up and returns vectors, by ID, from a single namespace.
# https://index_name-project_id.svc.environment.pinecone.io/vectors/fetch

# # POST Update
# # The Update operation updates vector in a namespace.
# # If a value is included, it will overwrite the previous value.
# https://index_name-project_id.svc.environment.pinecone.io/vectors/update

# # GET list_collections
# https://controller.unknown.pinecone.io/collections

# POST create_collection

# GET describe_collection

# DELETE delete_collection

# GET list_indexes

# POST create_index

# GET describe_index

# DELETEdelete_index

# Patch configure_index