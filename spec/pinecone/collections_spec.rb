require "spec_helper"

RSpec.describe Pinecone::Collection do
  let(:client) { Pinecone::Collection.new }
  let(:valid_attributes) {
    {
      name: "test-collection",
      source: "server-index" # Collections only work for server indexes
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
        client.delete("test-collection")
        wait_for_collection_deletion_completion("test-collection")
      end
    end

    describe "unsuccessful response" do
      let(:response) {
        client.create(valid_attributes)
      }

      before do
        client.create(valid_attributes)
      end

      it "returns an error response" do
        expect(response).to be_a(HTTParty::Response)
        expect(response.code).to eq(409)
        expect(response["error"]["message"]).to eq("Resource  already exists")
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
          "name" => "test-collection",
          "status" => "Initializing",
          "environment" => "us-east1-gcp"
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
      response = client.delete(collection_name)
      wait_for_collection_deletion_completion(collection_name)
      response
    }

    describe "successful response" do
      it "returns a response with collection deletion details" do
        expect(response).to be_a(HTTParty::Response)
        expect(response.code).to eq(202)
        expect(response.parsed_response).to be_nil
      end
    end
  end

  def wait_for_collection_deletion_completion(collection_name)
    timeout = 20
    interval = 0.5
    Timeout.timeout(timeout) do
      loop do
        response = client.describe(collection_name)
        break if response.code == 404
        sleep interval
      end
    end
  rescue Timeout::Error
    raise "Timed out waiting for upsert to complete"
  end
end
