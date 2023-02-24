module Pinecone
  class Client
    include HTTParty

    def initialize
      self.class.base_uri Pinecone.configuration.base_uri
      @headers = {
        "Content-Type" => "application/json",
        "Accept" => "application/json",
        "Api-Key" => Pinecone.configuration.api_key,
      }
    end

    # # Post Upsert
    # # The Upsert operation inserts or updates vectors in a namespace.
    # https://index_name-project_id.svc.environment.pinecone.io/vectors/upsert
    def upsert(body)
      payload = options.merge(body: body.to_json)
      self.class.post('/vectors/upsert', payload)
    end

    # # POST Query
    # https://index_name-project_id.svc.environment.pinecone.io/query
    # vector is an array of floats
    def query(vector)
      defaults = {
        "includeValues": false,
        "includeMetadata": true,
        "topK": 5,
        "vector": vector
      }.to_json
      payload = options.merge(body: defaults)
      self.class.post('/query', payload)
    end

    def options
      {
        headers: @headers,
      }
    end
  end
end