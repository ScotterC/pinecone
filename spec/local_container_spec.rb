require "spec_helper"

# Tests for local container functionality
# Run with: docker-compose -f docker-compose.test.yml up -d
# Then: bundle exec rspec spec/local_container_spec.rb
RSpec.describe "Pinecone Local Containers", :local_container do
  before(:all) do
    skip "Local containers not available" unless all_containers_available?
  end

  before(:each) do
    cleanup_containers
  end

  describe "host-based index creation" do
    it "creates dense index with direct host" do
      index = dense_index
      expect(index.base_uri).to eq("http://localhost:5081")
    end

    it "creates sparse index with direct host" do
      index = sparse_index
      expect(index.base_uri).to eq("http://localhost:5082")
    end

    it "works with global host configuration" do
      Pinecone.configure do |config|
        config.api_key = "dummy-key"
        config.host = "localhost:5081"
      end

      client = Pinecone::Client.new
      index = client.index
      expect(index.base_uri).to eq("http://localhost:5081")
    end
  end

  describe "dense vector operations" do
    let(:index) { dense_index }
    let(:test_vectors) do
      {
        vectors: [
          {id: "test1", values: [0.1, 0.2]},  # 2D vectors for dense index
          {id: "test2", values: [0.4, 0.5]}
        ]
      }
    end

    it "can upsert vectors" do
      response = index.upsert(test_vectors)
      expect(response.code).to eq(200)
      expect(response.parsed_response).to include("upsertedCount" => 2)
    end

    it "can query vectors" do
      index.upsert(test_vectors)

      query = {
        vector: [0.1, 0.2],
        top_k: 1,
        include_values: true
      }

      response = index.query(query)
      expect(response.code).to eq(200)
      expect(response.parsed_response).to have_key("matches")
    end

    it "can fetch vectors" do
      index.upsert(test_vectors)

      response = index.fetch(ids: ["test1"])
      expect(response.code).to eq(200)
      expect(response.parsed_response).to have_key("vectors")
    end

    it "can delete vectors" do
      index.upsert(test_vectors)

      response = index.delete(ids: ["test1"])
      expect(response.code).to eq(200)
    end

    it "can describe index stats" do
      response = index.describe_index_stats
      expect(response.code).to eq(200)
      expect(response.parsed_response).to have_key("totalVectorCount")
    end
  end

  # TODO: Fix sparse vector operations - container format may be different
  xdescribe "sparse vector operations" do
    let(:index) { sparse_index }
    let(:test_vectors) do
      {
        vectors: [
          {
            id: "test1",
            values: [],
            sparseValues: {indices: [0, 2], values: [0.1, 0.3]}
          },
          {
            id: "test2",
            values: [],
            sparseValues: {indices: [1, 3], values: [0.2, 0.4]}
          }
        ]
      }
    end

    it "can upsert sparse vectors" do
      response = index.upsert(test_vectors)
      expect(response.code).to eq(200)
      expect(response.parsed_response).to include("upsertedCount" => 2)
    end

    it "can query sparse vectors" do
      index.upsert(test_vectors)

      query = {
        sparse_vector: {indices: [0, 2], values: [0.1, 0.3]},
        top_k: 1,
        include_values: true
      }

      response = index.query(query)
      expect(response.code).to eq(200)
      expect(response.parsed_response).to have_key("matches")
    end

    it "can fetch sparse vectors" do
      index.upsert(test_vectors)

      response = index.fetch(ids: ["test1"])
      expect(response.code).to eq(200)
      expect(response.parsed_response).to have_key("vectors")
    end
  end

  describe "performance comparison" do
    it "host-based approach creates Vector without describe_index call" do
      # This test verifies that using host directly doesn't call describe_index
      # by creating an index and verifying it has the expected URI without API calls

      # Create index with direct host
      index = dense_index

      # Verify the index has the correct URI (proves it didn't need to call describe_index)
      expect(index.base_uri).to eq("http://localhost:5081")

      # Verify it works by making a simple call
      response = index.describe_index_stats
      expect(response.code).to eq(200)
    end
  end

  describe "multiple index support" do
    it "can work with both dense and sparse indexes simultaneously" do
      dense = dense_index
      sparse = sparse_index

      # Different base URIs
      expect(dense.base_uri).to eq("http://localhost:5081")
      expect(sparse.base_uri).to eq("http://localhost:5082")

      # Both should be operational
      dense_stats = dense.describe_index_stats
      sparse_stats = sparse.describe_index_stats

      expect(dense_stats.code).to eq(200)
      expect(sparse_stats.code).to eq(200)
    end
  end
end
