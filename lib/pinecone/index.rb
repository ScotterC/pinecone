# frozen_string_literal: true

module Pinecone
  class Index
    include HTTParty
    parser Pinecone::ResponseParser

    def initialize
      self.class.base_uri "https://api.pinecone.io"
      @headers = {
        "Content-Type" => "application/json",
        "Accept" => "application/json",
        "Api-Key" => Pinecone.configuration.api_key
      }
    end

    def list
      self.class.get("/indexes", options)
    end

    def describe(index_name)
      self.class.get("/indexes/#{index_name}", options)
    end

    def create(body)
      payload = options.merge(body: body.to_json)
      self.class.post("/indexes", payload)
    end

    def delete(index_name)
      self.class.delete("/indexes/#{index_name}", options)
    end

    def configure(index_name, body)
      payload = options.merge(body: body.to_json)
      self.class.patch("/indexes/#{index_name}", payload)
    end

    def options
      {
        headers: @headers
      }
    end
  end
end
