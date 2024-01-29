require "spec_helper"

RSpec.describe Pinecone::Index do
  let(:client) { Pinecone::Index.new }
  let(:valid_attributes) {
    {
      metric: "dotproduct",
      name: "test-index",
      dimension: 3
    }
  }

  describe "#list", :vcr do
    let(:response) {
      client.list
    }

    describe "successful response" do
      it "returns a response with list of indexes" do
        expect(response).to be_a(HTTParty::Response)
        expect(response.code).to eq(200)
        expect(response.parsed_response).to be_a(Array)
        expect(response.parsed_response).to include("test-index")
      end
    end
  end

  describe "#create", :vcr do
    let(:response) {
      client.create(valid_attributes)
    }

    describe "successful response" do
      it "returns a response with index creation details" do
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
        expect(response.parsed_response).to eq("index test-index already exists")
      end
    end
  end

  describe "#describe", :vcr do
    let(:response) {
      client.create(valid_attributes)
      client.describe("test-index")
    }

    describe "successful response" do
      it "returns a response with index details" do
        expect(response).to be_a(HTTParty::Response)
        expect(response.code).to eq(200)
        expect(response.parsed_response).to eq({
          "database" => {
            "dimension" => 3,
            "metric" => "dotproduct",
            "name" => "test-index",
            "pod_type" => "p1.x1",
            "pods" => 1,
            "replicas" => 1,
            "shards" => 1
          },
          "status" => {
            "crashed" => [],
            "host" => "test-index-b2e8921.svc.#{ENV["PINECONE_ENVIRONMENT"]}.pinecone.io",
            "port" => 433,
            "ready" => true,
            "state" => "Ready",
            "waiting" => []
          }
        })
      end
    end
  end

  describe "#delete", :vcr do
    let(:index_name) { "test-index" }

    before do
      client.create({
        metric: "dotproduct",
        name: index_name,
        dimension: 3
      })
    end

    let(:response) {
      client.delete(index_name)
    }

    describe "successful response" do
      it "returns a response with index deletion details" do
        expect(response).to be_a(HTTParty::Response)
        expect(response.code).to eq(202)
        expect(response.parsed_response).to be_nil
      end
    end
  end

  describe "#configure_index", :vcr do
    let(:index_name) { "example-index" }

    let(:response) {
      client.configure(index_name, replicas: 2)
    }

    describe "successful response" do
      it "returns a 200 that it's been updated" do
        expect(response).to be_a(HTTParty::Response)
        expect(response.code).to eq(202)
        expect(response.parsed_response).to be_nil
      end
    end
  end
end
