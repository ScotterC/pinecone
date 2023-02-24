module Pinecone
  class Vector
    include HTTParty

    def initialize(index_name)
      self.class.base_uri set_base_uri(index_name)

      @headers = {
        "Content-Type" => "application/json",
        "Accept" => "application/json",
        "Api-Key" => Pinecone.configuration.api_key,
      }
    end

    def upsert(body)
      payload = options.merge(body: body.to_json)
      self.class.post('/vectors/upsert', payload)
    end

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

    private

    # https://index_name-project_id.svc.environment.pinecone.io
    def set_base_uri(index_name)
      index_description = Pinecone::Index.new.describe(index_name)
      raise Pinecone::IndexNotFoundError, "Index #{index_name} does not exist" if index_description.code != 200
      uri = index_description.parsed_response["status"]["host"]
      "https://#{uri}"
    end
  end
end