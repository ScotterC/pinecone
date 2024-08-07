require "spec_helper"

RSpec.describe Pinecone::Client do
  let(:client) { Pinecone::Client.new }

  describe "#index", :vcr do
    it "allows multiple indices" do
      index_1 = client.index("serverless-index")
      index_2 = client.index("server-index")
      expect(index_1.base_uri).to match(/serverless-index/)
      expect(index_2.base_uri).to match(/server-index/)
    end
  end

  describe "#upsert", :vcr do
    let(:data) { {vectors: [{values: [1, 2, 3], id: "1"}]} }
    let(:response) {
      index = client.index("serverless-index")
      index.upsert(data)
    }

    describe "successfull response" do
      let(:response) {
        index = client.index("serverless-index")
        index.upsert(data)
      }
      it "returns a response" do
        expect(response).to be_a(HTTParty::Response)
        expect(response.parsed_response).to eq({"upsertedCount" => 1})
      end
    end
  end
end
