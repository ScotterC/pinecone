# frozen_string_literal: true

module Pinecone
  class Client
    include HTTParty

    def list_indexes
      Pinecone::Index.new.list
    end

    def describe_index(index_name)
      Pinecone::Index.new.describe(index_name)
    end

    def create_index(body)
      Pinecone::Index.new.create(body)
    end

    def delete_index(index_name)
      Pinecone::Index.new.delete(index_name)
    end

    def configure_index(index_name, body)
      Pinecone::Index.new.configure(index_name, body)
    end

    def list_collections
      Pinecone::Collection.new.list
    end

    def describe_collection(collection_name)
      Pinecone::Collection.new.describe(collection_name)
    end

    def create_collection(body)
      Pinecone::Collection.new.create(body)
    end

    def delete_collection(collection_name)
      Pinecone::Collection.new.delete(collection_name)
    end

    # This is a very confusing naming convention
    # Pinecone's reference now delineates between 'control plane' and 'data plane' which we'll reflect eventually
    def index(index_name = nil, host: nil)
      # Direct host provided
      return Pinecone::Vector.new(host: host) if host

      # Use global host if configured
      return Pinecone::Vector.new(host: Pinecone.configuration.host) if Pinecone.configuration.host

      # Legacy: index name provided
      if index_name
        unless Pinecone.configuration.silence_deprecation_warnings?
          warn "[DEPRECATED] client.index('name') is deprecated. Use client.index(host: 'host') for better performance."
        end
        return Pinecone::Vector.new(index_name)
      end

      # No host available
      raise ArgumentError,
        "No host provided. Set via Pinecone.configure { |c| c.host = 'host' } or client.index(host: 'host')"
    end
  end
end
