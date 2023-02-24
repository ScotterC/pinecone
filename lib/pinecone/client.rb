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

    # This is a very confusing naming convention
    def index(index_name)
      @index ||= Pinecone::Vector.new(index_name)
    end
  end
end