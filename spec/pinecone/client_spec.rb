require "spec_helper"

RSpec.describe Pinecone::Client do
  let(:client) { Pinecone::Client.new }

  before :all do
    VCR.use_cassette("create_index") do
      Pinecone::Client.new.create_index(
        {
          metric: "dotproduct",
          name: "example-index",
          dimension: 3
        }
      )
    end
  end

  describe "#index", :vcr do
    let(:parsed_response_1) {
      {"status" => {"host" => "example-index-1.svc.us-west4-gcp-free.pinecone.io"}}
    }
    let(:parsed_response_2) {
      {"status" => {"host" => "example-index-2.svc.us-west4-gcp-free.pinecone.io"}}
    }

    it "allows multiple indices" do
      response_1 = instance_double(HTTParty::Response, body: "", code: 200, parsed_response: parsed_response_1)
      allow_any_instance_of(Pinecone::Index).to receive(:describe).and_return(response_1)
      index_1 = client.index("example-index-1")

      response_2 = instance_double(HTTParty::Response, body: "", code: 200, parsed_response: parsed_response_2)
      allow_any_instance_of(Pinecone::Index).to receive(:describe).and_return(response_2)
      index_2 = client.index("example-index-2")

      expect(index_1.base_uri).to match(/example-index-1/)
      expect(index_2.base_uri).to match(/example-index-2/)
    end
  end

  describe "#upsert", :vcr do
    let(:data) { {vectors: [{values: [1, 2, 3], id: "1"}]} }
    let(:response) {
      index = client.index("example-index")
      index.upsert(data)
    }

    describe "successfull response" do
      let(:response) {
        index = client.index("example-index")
        index.upsert(data)
      }
      it "returns a response" do
        expect(response).to be_a(HTTParty::Response)
        expect(response.parsed_response).to eq({"upsertedCount" => 1})
      end
    end
  end
end
