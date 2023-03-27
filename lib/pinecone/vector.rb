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

    def delete(namespace: "", ids: [], delete_all: false)
      inputs = {
        "namespace": namespace,
        "ids": ids,
        "deleteAll": delete_all,
      }.to_json
      payload = options.merge(body: inputs)
      self.class.post('/vectors/delete', payload)
    end

    # This requires manually building the query string to unbundle ids
    def fetch(namespace: "", ids: [])
      ids_query_string = ids.map { |id| "ids=#{id}" }.join('&')
      query_string = "namespace=#{namespace}&#{ids_query_string}"
      self.class.get("/vectors/fetch?#{query_string}", options)
    end

    def upsert(body)
      payload = options.merge(body: body.to_json)
      self.class.post('/vectors/upsert', payload)
    end

    def query(namespace: "", vector:, top_k: 10, include_values: false, include_metadata: true)
      inputs = {
        "namespace": namespace,
        "includeValues": include_values,
        "includeMetadata": include_metadata,
        "topK": top_k,
        "vector": vector,
      }.to_json
      payload = options.merge(body: inputs)
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