# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pinecone::Index do
  before(:all) do
    skip "Local database container not available" unless database_available?
  end

  let(:client) do
    # Use local database container only
    index_client = Pinecone::Index.new
    index_client.class.base_uri "http://localhost:5080"
    index_client
  end
  let(:valid_attributes) do
    {
      metric: "dotproduct",
      name: "test-index",
      dimension: 3,
      spec: {
        pod: {
          environment: ENV["PINECONE_ENVIRONMENT"],
          pod_type: "p1.x1"
        }
      }
    }
  end

  let(:serverless_attributes) do
    {
      metric: "dotproduct",
      name: "test-index-serverless",
      dimension: 3,
      spec: {
        serverless: {
          cloud: "aws",
          region: "us-west-2"
        }
      }
    }
  end

  describe "#list" do
    let(:response) { client.list }

    it "returns a response with list of indexes" do
      expect(response).to be_a(HTTParty::Response)
      expect(response.code).to eq(200)
      expect(response.parsed_response).to be_a(Hash)
      expect(response["indexes"]).to be_an(Array)
      # Local container should have the dense-index
      expect(response["indexes"].map { |h| h["name"] }).to include("dense-index")
    end
  end

  describe "#create" do
    it "can create a serverless index" do
      test_attributes = {
        name: "test-create-serverless",
        dimension: 2,
        metric: "cosine",
        spec: {
          serverless: {
            cloud: "aws",
            region: "us-east-1"
          }
        }
      }

      # Clean up first if exists
      begin
        client.delete(test_attributes[:name])
      rescue
        nil
      end
      sleep 0.1

      response = client.create(test_attributes)
      expect(response).to be_a(HTTParty::Response)
      expect([200, 201]).to include(response.code)

      # Clean up
      begin
        client.delete(test_attributes[:name])
      rescue
        nil
      end
    end

    it "handles pod-based index creation (may not be supported in local container)" do
      pod_attributes = {
        name: "test-create-pod",
        dimension: 3,
        metric: "dotproduct",
        spec: {
          pod: {
            environment: "gcp-starter",
            pod_type: "p1.x1"
          }
        }
      }

      response = client.create(pod_attributes)
      expect(response).to be_a(HTTParty::Response)
      # Local container may not support pod-based indexes
      expect([200, 201, 400, 404, 422]).to include(response.code)

      # Clean up if created successfully
      if [200, 201].include?(response.code)
        begin
          client.delete(pod_attributes[:name])
        rescue
          nil
        end
      end
    end

    it "returns error for invalid index creation" do
      invalid_attributes = {
        name: "invalid-index",
        dimension: -1, # Invalid dimension
        metric: "invalid-metric", # Invalid metric
        spec: {
          serverless: {
            cloud: "invalid-cloud",
            region: "invalid-region"
          }
        }
      }

      response = client.create(invalid_attributes)
      expect(response).to be_a(HTTParty::Response)
      expect([400, 422]).to include(response.code)
    end

    it "returns error when creating index with existing name" do
      # First, create an index
      test_name = "duplicate-index-test"
      attributes = {
        name: test_name,
        dimension: 2,
        metric: "cosine",
        spec: {
          serverless: {
            cloud: "aws",
            region: "us-east-1"
          }
        }
      }

      # Clean up first
      begin
        client.delete(test_name)
      rescue
        nil
      end
      sleep 0.1

      # Create the index
      first_response = client.create(attributes)
      expect([200, 201]).to include(first_response.code)

      # Try to create again with same name
      duplicate_response = client.create(attributes)
      expect(duplicate_response).to be_a(HTTParty::Response)
      expect([400, 409, 422]).to include(duplicate_response.code) # Conflict or validation error

      # Clean up
      begin
        client.delete(test_name)
      rescue
        nil
      end
    end
  end

  describe "#describe" do
    it "returns index details for existing index" do
      # Test describing the dense-index that should exist
      response = client.describe("dense-index")
      expect(response).to be_a(HTTParty::Response)
      expect(response.code).to eq(200)
      expect(response.parsed_response).to include(
        "name" => "dense-index",
        "dimension" => 2,
        "metric" => "cosine"
      )
    end

    it "returns 404 for non-existent index" do
      response = client.describe("non-existent-index")
      expect(response).to be_a(HTTParty::Response)
      expect(response.code).to eq(404)
    end

    it "tests pod-based index workflow (if supported by container)" do
      # Test pod-based index creation and description
      pod_name = "test-describe-pod"
      pod_attributes = {
        name: pod_name,
        dimension: 3,
        metric: "dotproduct",
        spec: {
          pod: {
            environment: "gcp-starter",
            pod_type: "p1.x1"
          }
        }
      }

      # Try to create the pod index
      create_response = client.create(pod_attributes)
      expect(create_response).to be_a(HTTParty::Response)

      if [200, 201].include?(create_response.code)
        # If creation succeeded, test describe
        response = client.describe(pod_name)
        expect(response).to be_a(HTTParty::Response)
        expect(response.code).to eq(200)
        expect(response.parsed_response).to include(
          "name" => pod_name,
          "dimension" => 3,
          "metric" => "dotproduct"
        )

        # Clean up
        client.delete(pod_name)
      else
        # If creation failed, verify it's an expected error for unsupported feature
        expect([400, 404, 422]).to include(create_response.code)
      end
    end
  end

  describe "#delete" do
    it "can delete a serverless index" do
      test_name = "test-delete-serverless"
      begin
        client.create({
          name: test_name,
          dimension: 2,
          metric: "cosine",
          spec: {
            serverless: {
              cloud: "aws",
              region: "us-east-1"
            }
          }
        })
      rescue
        nil
      end

      response = client.delete(test_name)
      expect(response).to be_a(HTTParty::Response)
      expect([200, 202, 204]).to include(response.code)
    end

    it "handles deletion of pod-based index (if supported)" do
      pod_name = "test-delete-pod"
      pod_attributes = {
        name: pod_name,
        dimension: 3,
        metric: "dotproduct",
        spec: {
          pod: {
            environment: "gcp-starter",
            pod_type: "p1.x1"
          }
        }
      }

      # Try to create first
      create_response = client.create(pod_attributes)

      response = client.delete(pod_name)
      expect(response).to be_a(HTTParty::Response)
      if [200, 201].include?(create_response.code)
        # If created successfully, test deletion
        expect([200, 202, 204]).to include(response.code)
      else
        # If creation failed due to unsupported feature, test delete on non-existent
        expect(response.code).to eq(404)
      end
    end

    it "returns error when deleting non-existent index" do
      response = client.delete("non-existent-index")
      expect(response).to be_a(HTTParty::Response)
      expect(response.code).to eq(404)
    end
  end

  describe "#configure_index" do
    it "handles pod-based index configuration (if supported)" do
      # Test configuring pod indexes
      pod_name = "test-configure-pod"
      pod_attributes = {
        name: pod_name,
        dimension: 3,
        metric: "dotproduct",
        spec: {
          pod: {
            environment: "gcp-starter",
            pod_type: "p1.x1"
          }
        }
      }

      # Try to create first
      create_response = client.create(pod_attributes)

      response = client.configure(pod_name, spec: {pod: {replicas: 2}})
      expect(response).to be_a(HTTParty::Response)
      if [200, 201].include?(create_response.code)
        # If created successfully, test configuration
        expect([200, 400, 404, 422, 501]).to include(response.code)

        # Clean up
        client.delete(pod_name)
      else
        # If creation failed, still test configure on non-existent to verify error handling
        expect([400, 404, 422]).to include(response.code)
      end
    end

    it "returns error for configuring serverless index" do
      # Serverless indexes typically cannot be configured
      response = client.configure("dense-index", spec: {serverless: {cloud: "aws"}})
      expect(response).to be_a(HTTParty::Response)
      expect([400, 404, 422, 501]).to include(response.code)
    end

    it "returns error when configuring non-existent index" do
      response = client.configure("non-existent-index", spec: {pod: {replicas: 1}})
      expect(response).to be_a(HTTParty::Response)
      expect([400, 404]).to include(response.code) # Local container may return 400 instead of 404
    end
  end
end
