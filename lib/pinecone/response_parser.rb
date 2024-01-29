module Pinecone
  class ResponseParser < HTTParty::Parser
    # standard:disable Naming/ConstantName
    SupportedFormats = {
      "application/json" => :json,
      "text/plain" => :json
    }
    # standard:enable Naming/ConstantName

    def json
      JSON.parse(body)
    rescue
      body
    end
  end
end
