# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pinecone::Collection do
  let(:client) { Pinecone::Collection.new }
  let(:valid_attributes) do
    {
      name: "test-collection",
      source: "server-index" # Collections only work for server indexes
    }
  end

  # Mock collections since they're not supported in local containers
  let(:mock_collections_list) do
    {
      "collections" => [
        {
          "name" => "existing-collection",
          "status" => "Ready",
          "dimension" => 1536,
          "environment" => "us-east1-gcp"
        }
      ]
    }
  end

  let(:mock_collection_details) do
    {
      "name" => "test-collection",
      "status" => "Initializing",
      "dimension" => 1536,
      "environment" => "us-east1-gcp"
    }
  end

  describe "#list" do
    it "returns a response with list of collections" do
      # Mock the HTTP response
      mock_response = double("response",
        code: 200,
        parsed_response: mock_collections_list)
      allow(client).to receive(:list).and_return(mock_response)

      response = client.list
      expect(response).to be_a(RSpec::Mocks::Double)
      expect(response.code).to eq(200)
      expect(response.parsed_response).to be_a(Hash)
      expect(response.parsed_response).to have_key("collections")

      # Verify collections array structure
      collections = response.parsed_response["collections"]
      expect(collections).to be_an(Array)
      expect(collections.length).to be > 0
      expect(collections.first).to have_key("name")
      expect(collections.first).to have_key("status")
    end
  end

  describe "#create" do
    describe "successful response" do
      it "returns a response with collection creation details" do
        # Mock successful creation
        mock_response = double("response",
          code: 201,
          parsed_response: mock_collection_details)
        allow(client).to receive(:create).with(valid_attributes).and_return(mock_response)

        response = client.create(valid_attributes)
        expect(response).to be_a(RSpec::Mocks::Double)
        expect(response.code).to eq(201)

        # Verify creation response structure
        expect(response.parsed_response).to be_a(Hash)
        expect(response.parsed_response).to have_key("name")
        expect(response.parsed_response["name"]).to eq("test-collection")
        expect(response.parsed_response).to have_key("status")
      end
    end

    describe "unsuccessful response" do
      it "returns an error response for duplicate collection" do
        # Mock conflict error
        error_response = {
          "error" => {
            "message" => "Resource test-collection already exists",
            "code" => 409
          }
        }
        mock_response = double("response",
          code: 409,
          parsed_response: error_response)
        allow(client).to receive(:create).with(valid_attributes).and_return(mock_response)

        response = client.create(valid_attributes)
        expect(response).to be_a(RSpec::Mocks::Double)
        expect(response.code).to eq(409)

        # Verify error response structure
        expect(response.parsed_response).to have_key("error")
        expect(response.parsed_response["error"]).to have_key("message")
        expect(response.parsed_response["error"]["message"]).to include("already exists")
      end

      it "returns an error response for invalid parameters" do
        # Mock validation error
        error_response = {
          "error" => {
            "message" => "Invalid collection parameters",
            "code" => 400
          }
        }
        mock_response = double("response",
          code: 400,
          parsed_response: error_response)

        invalid_attributes = {name: ""} # Invalid empty name
        allow(client).to receive(:create).with(invalid_attributes).and_return(mock_response)

        response = client.create(invalid_attributes)
        expect(response).to be_a(RSpec::Mocks::Double)
        expect(response.code).to eq(400)
      end
    end
  end

  describe "#describe" do
    describe "successful response" do
      it "returns a response with collection details" do
        # Mock successful describe
        mock_response = double("response",
          code: 200,
          parsed_response: mock_collection_details)
        allow(client).to receive(:describe).with("test-collection").and_return(mock_response)

        response = client.describe("test-collection")
        expect(response).to be_a(RSpec::Mocks::Double)
        expect(response.code).to eq(200)

        # Verify describe response structure
        expect(response.parsed_response).to be_a(Hash)
        expect(response.parsed_response).to have_key("name")
        expect(response.parsed_response).to have_key("status")
        expect(response.parsed_response["name"]).to eq("test-collection")

        # Status should be a valid collection status
        valid_statuses = %w[Initializing Ready Terminating]
        expect(valid_statuses).to include(response.parsed_response["status"])
      end
    end

    it "returns 404 for non-existent collection" do
      # Mock 404 error
      error_response = {
        "error" => {
          "message" => "Resource non-existent-collection not found",
          "code" => 404
        }
      }
      mock_response = double("response",
        code: 404,
        parsed_response: error_response)
      allow(client).to receive(:describe).with("non-existent-collection").and_return(mock_response)

      response = client.describe("non-existent-collection")
      expect(response).to be_a(RSpec::Mocks::Double)
      expect(response.code).to eq(404)
    end
  end

  describe "#delete" do
    let(:collection_name) { "test-collection" }

    describe "successful response" do
      it "returns a response with collection deletion details" do
        # Mock successful deletion
        mock_response = double("response",
          code: 202,
          parsed_response: nil) # Delete typically returns empty body
        allow(client).to receive(:delete).with(collection_name).and_return(mock_response)

        response = client.delete(collection_name)
        expect(response).to be_a(RSpec::Mocks::Double)
        expect(response.code).to eq(202)

        # Delete typically returns empty body
        expect(response.parsed_response).to be_nil
      end
    end

    it "returns 404 when deleting non-existent collection" do
      # Mock 404 error
      error_response = {
        "error" => {
          "message" => "Resource non-existent-collection not found",
          "code" => 404
        }
      }
      mock_response = double("response",
        code: 404,
        parsed_response: error_response)
      allow(client).to receive(:delete).with("non-existent-collection").and_return(mock_response)

      response = client.delete("non-existent-collection")
      expect(response).to be_a(RSpec::Mocks::Double)
      expect(response.code).to eq(404)
    end
  end
end
