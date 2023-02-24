require 'spec_helper'


RSpec.describe Pinecone::Vector do
  let(:index) { 
    VCR.use_cassette("use_index") do
      Pinecone::Vector.new("example-index") 
    end
  }

  describe "#upsert", :vcr do
    let(:data) { { vectors: [{ values: [1, 2, 3], id: "1" }] } }
    let(:response) {
      index.upsert(data)
    }      

    describe "successfull response" do
      let(:response) {
        index.upsert(data)
      }  
      it "returns a response" do
        expect(response).to be_a(HTTParty::Response)
        expect(response.parsed_response).to eq({"upsertedCount"=>1})
      end
    end

    describe "unsuccessfull response" do
      let(:response) {
        index.upsert("foo")
      } 
      it "returns a response" do
        expect(response).to be_a(HTTParty::Response)
        expect(response.code).to eq(400)
        expect(response.parsed_response).to eq(": Root element must be a message.")
      end
    end
  end

  describe "#query", :vcr do
    let(:data) { { 
      vectors: [
        { values: [1, 2, 3], id: "1" },
        { values: [0, 1, -1], id: "2" },
        { values: [1, -1, 0], id: "3" }
      ] 
    } }

    before do
      index.upsert(data)
    end

    let(:response) {
      index.query([0.5, -0.5, 0])
    }      

    describe "successfull response" do
      it "returns a response" do
        expect(response).to be_a(HTTParty::Response)
        expect(response.parsed_response).to eq({
              "results" => [],
              "matches" => [
                {
                        "id" => "3",
                    "score" => 1,
                    "values" => []
                },
                {
                        "id" => "2",
                    "score" => -0.5,
                    "values" => []
                },
                {
                        "id" => "1",
                    "score" => -0.5,
                    "values" => []
                }
            ],
            "namespace" => ""
        })
      end
    end
  end

end