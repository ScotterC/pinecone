require 'spec_helper'

RSpec.describe Pinecone::Client do
  let(:client) { Pinecone::Client.new }

  describe "#upsert", :vcr do
    let(:data) { { vectors: [{ values: [1, 2, 3], id: "1" }] } }
    let(:response) {
      client.upsert(data)
    }      

    describe "successfull response" do
      let(:response) {
        client.upsert(data)
      }  
      it "returns a response" do
        expect(response).to be_a(HTTParty::Response)
        expect(response.parsed_response).to eq({"upsertedCount"=>1})
      end
    end

    describe "unsuccessfull response" do
      let(:response) {
        client.upsert("foo")
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
      client.upsert(data)
    end

    let(:response) {
      client.query([0.5, -0.5, 0])
    }      

    describe "successfull response" do
      it "returns a response" do
        expect(response).to be_a(HTTParty::Response)
        expect(response.parsed_response).to eq({
              "results" => [],
              "matches" => [
                {
                        "id" => "3",
                    "score" => 1.00000012,
                    "values" => []
                },
                {
                        "id" => "1",
                    "score" => -0.188982248,
                    "values" => []
                },
                {
                        "id" => "2",
                    "score" => -0.50000006,
                    "values" => []
                }
            ],
            "namespace" => ""
        })
      end
    end
  end
end