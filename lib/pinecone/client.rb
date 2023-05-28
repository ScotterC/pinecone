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
    def index(index_name)
      Pinecone::Vector.new(index_name)
    end
  end
end