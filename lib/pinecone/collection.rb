module Pinecone
  class Collection
    include HTTParty

    def initialize
      @base_uri = "https://controller.#{Pinecone.configuration.environment}.pinecone.io"

      @headers = {
        "Content-Type" => "application/json",
        "Accept" => "application/json",
        "Api-Key" => Pinecone.configuration.api_key,
      }
    end

    def list
      self.class.get('/collections', options)
    end

    def describe(collection_name)
      self.class.get("/collections/#{collection_name}", options)
    end

    def create(body)
      payload = options.merge(body: body.to_json)
      self.class.post('/collections', payload)
    end

    def delete(collection_name)
      self.class.delete("/collections/#{collection_name}", options)
    end

    def options
      {
        headers: @headers,
      }
    end
  end
end