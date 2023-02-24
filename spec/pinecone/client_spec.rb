require 'spec_helper'

RSpec.describe Pinecone::Client do
  let(:client) { Pinecone::Client.new }

  before :all do
    VCR.use_cassette("create_index") do
      Pinecone::Client.new.create_index(
        {
          "metric": "dotproduct",
          "name": "example-index",
          "dimension": 3,
        }
      )
    end
  end

  describe "#upsert", :vcr do
    let(:data) { { vectors: [{ values: [1, 2, 3], id: "1" }] } }
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
        expect(response.parsed_response).to eq({"upsertedCount"=>1})
      end
    end
  end
end