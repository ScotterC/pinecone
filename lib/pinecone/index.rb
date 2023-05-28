module Pinecone
  class Index
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
      self.class.get("#{@base_uri}/databases", options)
    end

    def describe(index_name)
      self.class.get("#{@base_uri}/databases/#{index_name}", options)
    end
    
    def create(body)
      payload = options.merge(body: body.to_json)
      self.class.post("#{@base_uri}/databases", payload)
    end

    def delete(index_name)
      self.class.delete("#{@base_uri}/databases/#{index_name}", options)
    end

    def configure(index_name, body)
      payload = options.merge(body: body.to_json)
      self.class.patch("#{@base_uri}/databases/#{index_name}", payload)
    end

    def options
      {
        headers: @headers,
      }
    end
  end
end