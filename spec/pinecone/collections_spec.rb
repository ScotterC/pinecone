require "spec_helper"

RSpec.describe Pinecone::Collection do
  let(:client) { Pinecone::Collection.new }
  let(:valid_attributes) {
    {
      name: "test-collection",
      source: "test-index"
    }
  }

  describe "#list", :vcr do
    let(:response) {
      client.list
    }

    it "returns a response with list of collections" do
      expect(response).to be_a(HTTParty::Response)
      expect(response.code).to eq(200)
      expect(response.parsed_response).to be_a(Hash)
    end
  end

  describe "#create", :vcr do
    let(:response) {
      client.create(valid_attributes)
    }

    describe "successful response" do
      it "returns a response with collection creation details" do
        expect(response).to be_a(HTTParty::Response)
        expect(response.code).to eq(201)
      end
    end

    describe "unsuccessful response" do
      let(:response) {
        client.create(valid_attributes)
      }

      it "returns an error response" do
        expect(response).to be_a(HTTParty::Response)
        expect(response.code).to eq(409)
        expect(response.parsed_response).to eq("collection request test-collection already exists")
      end
    end
  end

  describe "#describe", :vcr do
    let(:response) {
      client.create(valid_attributes)
      client.describe("test-collection")
    }

    describe "successful response" do
      it "returns a response with collection details" do
        expect(response).to be_a(HTTParty::Response)
        expect(response.code).to eq(200)
        expect(response.parsed_response).to eq({
          "name"=>"test-collection", 
          "size"=>0,
          "status"=>"Initializing", 
          "dimension"=>3,
          "vector_count"=>0
        })
      end
    end
  end

  describe "#delete", :vcr do
    let(:collection_name) { "test-collection" }

    before do
      client.create({
        metric: "dotproduct",
        name: collection_name,
        dimension: 3
      })
    end

    let(:response) {
      client.delete(collection_name)
    }

    describe "successful response" do
      it "returns a response with collection deletion details" do
        expect(response).to be_a(HTTParty::Response)
        expect(response.code).to eq(202)
        expect(response.parsed_response).to be_nil
      end
    end
  end
end
