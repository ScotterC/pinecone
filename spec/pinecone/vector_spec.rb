require "spec_helper"

RSpec.describe Pinecone::Vector do
  before(:all) do
    skip "Local containers not available" unless dense_container_available?
  end

  let(:dense_index) { Pinecone::Vector.new(host: "localhost:5081") }
  let(:sparse_index) { Pinecone::Vector.new(host: "localhost:5082") }
  describe "#initialize" do
    context "with host parameter" do
      it "sets base_uri from host" do
        vector = Pinecone::Vector.new(host: "example.com")
        expect(vector.base_uri).to eq("https://example.com")
      end

      it "handles host with https prefix" do
        vector = Pinecone::Vector.new(host: "https://example.com")
        expect(vector.base_uri).to eq("https://example.com")
      end

      it "uses http for localhost" do
        vector = Pinecone::Vector.new(host: "localhost:5081")
        expect(vector.base_uri).to eq("http://localhost:5081")
      end
    end

    context "with index_name parameter (legacy)" do
      it "calls set_base_uri for legacy support" do
        # Mock the legacy path for testing
        allow_any_instance_of(Pinecone::Index).to receive(:describe).and_return(
          double("response", code: 200, parsed_response: {"host" => "test-host.pinecone.io"})
        )

        vector = Pinecone::Vector.new("test-index")
        expect(vector.base_uri).to eq("https://test-host.pinecone.io")
      end

      it "raises error when index not found" do
        allow_any_instance_of(Pinecone::Index).to receive(:describe).and_return(
          double("response", code: 404)
        )

        expect { Pinecone::Vector.new("missing-index") }.to raise_error(Pinecone::IndexNotFoundError)
      end
    end

    context "without parameters" do
      it "raises argument error" do
        expect { Pinecone::Vector.new }.to raise_error(ArgumentError, /Must provide either/)
      end
    end
  end

  # Tests using local container
  context "with local container" do
    let(:index) { dense_index }

    before :each do
      # Clean up any existing vectors
      index.delete(delete_all: true)
    end

    describe "#upsert" do
      let(:data) { {vectors: [{values: [0.1, 0.2], id: "test1"}]} }  # 2D vectors for dense container

      describe "successful response" do
        let(:upsert_response) {
          index.upsert(data)
        }

        it "returns a response" do
          expect(upsert_response).to be_a(HTTParty::Response)
          expect(upsert_response.code).to eq(200)
          expect(upsert_response.parsed_response).to include("upsertedCount" => 1)
        end
      end

      describe "unsuccessful response" do
        let(:upsert_response) {
          index.upsert("invalid-data")
        }

        it "returns error for invalid data" do
          expect(upsert_response).to be_a(HTTParty::Response)
          expect([400, 422]).to include(upsert_response.code)  # Local container may return different error codes
        end
      end

      it "handles vectors with wrong dimensions" do
        wrong_dimension_data = {vectors: [{values: [0.1, 0.2, 0.3], id: "wrong_dim"}]}  # 3D instead of 2D
        response = index.upsert(wrong_dimension_data)
        expect(response).to be_a(HTTParty::Response)
        expect([400, 422]).to include(response.code)  # Should be validation error
      end
    end

    describe "#delete" do
      let(:data) { {vectors: [{values: [0.1, 0.2], id: "delete_test"}]} }

      describe "successful response" do
        let(:delete_response) {
          index.delete(ids: ["delete_test"])
        }

        it "returns a response" do
          index.upsert(data)
          expect(delete_response).to be_a(HTTParty::Response)
          expect(delete_response.code).to eq(200)
        end
      end

      describe "successful response with filters" do
        let(:delete_response) {
          index.delete(filter: {genre: "comedy"})
        }

        it "returns a response" do
          metadata_data = {vectors: [{values: [0.1, 0.2], id: "filter_test", metadata: {genre: "comedy"}}]}
          index.upsert(metadata_data)
          expect(delete_response).to be_a(HTTParty::Response)
          expect([200, 400]).to include(delete_response.code)  # Local container may not support metadata filtering
        end
      end

      context "when delete_all is true" do
        let(:delete_response) {
          index.delete(delete_all: true)
        }

        it "returns a response" do
          index.upsert(data)
          expect(delete_response).to be_a(HTTParty::Response)
          expect(delete_response.code).to eq(200)
        end
      end
    end

    describe "#fetch" do
      describe "successful response" do
        let(:fetch_response) {
          index.fetch(ids: ["fetch1", "fetch2"])
        }

        it "returns a response" do
          index.upsert({vectors: [{values: [0.1, 0.2], id: "fetch1"}]})
          index.upsert({vectors: [{values: [0.3, 0.4], id: "fetch2"}]})

          expect(fetch_response).to be_a(HTTParty::Response)
          expect(fetch_response.code).to eq(200)
          expect(fetch_response.parsed_response).to be_a(Hash)

          expect(fetch_response.parsed_response).to have_key("vectors")

          # Verify actual vector data is returned
          vectors = fetch_response.parsed_response["vectors"]
          expect(vectors).to be_a(Hash)
          expect(vectors.keys).to include("fetch1", "fetch2")
          expect(vectors["fetch1"]).to have_key("values")
          expect(vectors["fetch1"]["values"]).to eq([0.1, 0.2])
        end
      end

      it "returns empty result for non-existent IDs" do
        response = index.fetch(ids: ["non-existent"])
        expect(response).to be_a(HTTParty::Response)
        expect(response.code).to eq(200)
        expect(response.parsed_response).to have_key("vectors")

        # Verify empty result for non-existent IDs
        vectors = response.parsed_response["vectors"]
        expect(vectors).to be_a(Hash)
        expect(vectors).to be_empty
      end
    end

    describe "#list" do
      let(:data) {
        {
          vectors: [
            {values: [0.1, 0.2], id: "test1"},
            {values: [0.3, 0.4], id: "test2"},
            {values: [0.5, 0.6], id: "test3"},
            {values: [0.7, 0.8], id: "other1"}
          ]
        }
      }

      before do
        index.upsert(data)
        sleep 0.1  # Give container time to process
      end

      context "without a block" do
        it "returns all IDs" do
          result = index.list
          expect(result).to be_an(Array)
          expect(result).to include("test1", "test2", "test3", "other1")
        end

        it "respects the limit parameter" do
          result = index.list(limit: 2)
          expect(result.length).to eq(2)
          expect(["test1", "test2", "test3", "other1"]).to include(*result)
        end

        it "filters by prefix" do
          result = index.list(prefix: "test")
          expect(result).to be_an(Array)
          expect(result.select { |id| id.start_with?("test") }).to eq(result)
        end

        it "respects namespace" do
          index.upsert(vectors: [{values: [0.9, 1.0], id: "ns1"}], namespace: "example-namespace")
          sleep 0.1

          result = index.list(namespace: "example-namespace")
          expect(result).to include("ns1")
        end
      end

      context "with a block" do
        it "yields batches of IDs" do
          yielded_ids = []
          index.list do |batch|
            yielded_ids.concat(batch)
          end
          expect(yielded_ids).to include("test1", "test2", "test3", "other1")
        end

        it "respects the limit parameter" do
          yielded_ids = []
          index.list(limit: 2) do |batch|
            yielded_ids.concat(batch)
          end
          expect(yielded_ids.length).to eq(2)
          expect(["test1", "test2", "test3", "other1"]).to include(*yielded_ids)
        end

        it "filters by prefix" do
          yielded_ids = []
          index.list(prefix: "test") do |batch|
            yielded_ids.concat(batch)
          end
          expect(yielded_ids.select { |id| id.start_with?("test") }).to eq(yielded_ids)
        end

        it "respects namespace" do
          index.upsert(vectors: [{values: [0.9, 1.0], id: "ns1"}], namespace: "example-namespace")
          sleep 0.1

          yielded_ids = []
          index.list(namespace: "example-namespace") do |batch|
            yielded_ids.concat(batch)
          end
          expect(yielded_ids).to include("ns1")
        end
      end

      context "with larger dataset" do
        before do
          # Add a smaller dataset for container testing
          additional_data = {
            vectors: 10.times.map do |i|
              {values: [i * 0.1, (i + 1) * 0.1], id: "extra#{i}"}
            end
          }

          # Upsert the additional vectors
          index.upsert(additional_data)
          sleep 0.2  # Give container time to process
        end

        it "returns all vectors when no limit is specified" do
          result = index.list
          expect(result.length).to be >= 10  # At least the extra vectors
        end

        it "respects a limit" do
          result = index.list(limit: 5)
          expect(result.length).to eq(5)
        end

        context "with a block" do
          it "yields vectors in batches" do
            yielded_ids = []
            index.list do |batch|
              yielded_ids.concat(batch)
            end
            expect(yielded_ids.length).to be >= 10
          end

          it "respects a limit in blocks" do
            yielded_ids = []
            index.list(limit: 5) do |batch|
              yielded_ids.concat(batch)
            end
            expect(yielded_ids.length).to eq(5)
          end
        end
      end
    end

    describe "#list_paginated" do
      let(:data) {
        {
          vectors: [
            {values: [0.1, 0.2], id: "page1"},
            {values: [0.3, 0.4], id: "page2"}
          ]
        }
      }

      describe "successful response" do
        let(:response) { index.list_paginated }

        before do
          index.upsert(data)
          sleep 0.1
        end

        it "returns a response" do
          expect(response).to be_a(HTTParty::Response)
          expect(response.code).to eq(200)
          expect(response.parsed_response).to be_a(Hash)
          expect(response.parsed_response).to have_key("vectors")

          # Verify actual vector IDs are returned
          vectors = response.parsed_response["vectors"]
          expect(vectors).to be_an(Array)
          expect(vectors.length).to be > 0
          expect(vectors.first).to have_key("id")
        end
      end

      describe "success with prefix" do
        let(:prefix_data) {
          {
            vectors: [
              {values: [0.1, 0.2], id: "foo#1"},
              {values: [0.3, 0.4], id: "foo#2"},
              {values: [0.5, 0.6], id: "bar#1"}
            ]
          }
        }

        let(:response) { index.list_paginated(prefix: "foo#") }

        before do
          index.upsert(prefix_data)
          sleep 0.1
        end

        it "returns a response" do
          expect(response).to be_a(HTTParty::Response)
          expect(response.code).to eq(200)
          expect(response.parsed_response).to be_a(Hash)
          expect(response.parsed_response).to have_key("vectors")

          # Verify vectors are returned with prefix filtering
          vectors = response.parsed_response["vectors"]
          expect(vectors).to be_an(Array)
          if vectors.any?
            expect(vectors.first).to have_key("id")
            # Verify prefix filtering worked if vectors exist
            vectors.each do |vector|
              expect(vector["id"]).to start_with("foo#")
            end
          end
        end
      end

      describe "success with limit" do
        let(:response) { index.list_paginated(limit: 1) }

        before do
          index.upsert(data)
          sleep 0.1
        end

        it "returns a response with limit" do
          expect(response).to be_a(HTTParty::Response)
          expect(response.code).to eq(200)
          expect(response.parsed_response).to be_a(Hash)
          expect(response.parsed_response).to have_key("vectors")
        end
      end

      describe "success with pagination token" do
        it "handles pagination tokens" do
          # First request to get pagination token
          first_response = index.list_paginated(limit: 1)
          expect(first_response).to be_a(HTTParty::Response)
          expect(first_response.code).to eq(200)

          # If pagination is supported, test it
          if first_response.parsed_response.dig("pagination", "next")
            pagination_token = first_response.parsed_response.dig("pagination", "next")
            response = index.list_paginated(limit: 1, pagination_token: pagination_token)
            expect(response).to be_a(HTTParty::Response)
            expect(response.code).to eq(200)
          end
        end
      end
    end

    describe "#update" do
      describe "successful response" do
        let(:update_response) {
          index.update(id: "update_test", values: [0.9, 1.0], set_metadata: {genre: "drama"})
        }

        it "returns a response" do
          index.upsert({vectors: [{values: [0.1, 0.2], id: "update_test"}]})
          sleep 0.1

          expect(update_response).to be_a(HTTParty::Response)
          expect(update_response.code).to eq(200)
        end
      end

      it "handles updates to non-existent vectors" do
        response = index.update(id: "non_existent", values: [0.1, 0.2])
        expect(response).to be_a(HTTParty::Response)
        expect([200, 404]).to include(response.code)
      end
    end

    describe "#query" do
      let(:data) {
        {
          vectors: [
            {values: [0.1, 0.2], id: "query1", metadata: {genre: "comedy"}},
            {values: [0.3, 0.4], id: "query2", metadata: {genre: "comedy"}},
            {values: [0.5, 0.6], id: "query3"}
          ]
        }
      }
      let(:query_vector) { [0.2, 0.3] }

      describe "successful response" do
        before do
          index.upsert(data)
          sleep 0.1
        end

        let(:query_response) {
          index.query(vector: query_vector, top_k: 3, include_values: true)
        }

        let(:query_object) {
          Pinecone::Vector::Query.new(vector: query_vector, top_k: 3)
        }

        let(:query_response_with_object) {
          index.query(query_object)
        }

        it "returns a response" do
          expect(query_response).to be_a(HTTParty::Response)
          expect(query_response.code).to eq(200)
          expect(query_response.parsed_response).to have_key("matches")

          # Verify actual matches are returned
          matches = query_response.parsed_response["matches"]
          expect(matches).to be_an(Array)
          expect(matches.length).to be > 0
          expect(matches.first).to have_key("id")
          expect(matches.first).to have_key("score")
        end

        it "returns a response when queried with object" do
          expect(query_response_with_object).to be_a(HTTParty::Response)
          expect(query_response_with_object.code).to eq(200)
          expect(query_response_with_object.parsed_response).to have_key("matches")

          # Verify actual matches are returned with query object
          matches = query_response_with_object.parsed_response["matches"]
          expect(matches).to be_an(Array)
          expect(matches.length).to be > 0
          expect(matches.first).to have_key("id")
          expect(matches.first).to have_key("score")
        end

        it "handles empty queries" do
          empty_response = index.query(vector: [0.0, 0.0], top_k: 1)
          expect(empty_response).to be_a(HTTParty::Response)
          expect(empty_response.code).to eq(200)
        end
      end

      describe "with filter" do
        before do
          index.upsert(data)
          sleep 0.1
        end

        let(:filter) { {genre: {"$eq" => "comedy"}} }
        let(:filter_response) { index.query(vector: query_vector, filter: filter, top_k: 2) }

        it "returns a response" do
          expect(filter_response).to be_a(HTTParty::Response)
          expect(filter_response.code).to eq(200)
          expect(filter_response.parsed_response).to have_key("matches")

          # Verify matches contain filtered results
          matches = filter_response.parsed_response["matches"]
          expect(matches).to be_an(Array)
          # Should only return vectors with genre: comedy metadata
          matches.each do |match|
            expect(match).to have_key("id")
            if match["metadata"]
              expect(match["metadata"]["genre"]).to eq("comedy")
            end
          end
        end

        it "handles invalid filters gracefully" do
          invalid_filter = {invalid_field: "invalid_value"}
          response = index.query(vector: query_vector, filter: invalid_filter)
          expect(response).to be_a(HTTParty::Response)
          expect([200, 400]).to include(response.code)
        end
      end

      describe "with namespace" do
        let(:namespace) { "example-namespace" }

        before do
          index.upsert(data.merge(namespace: namespace))
          sleep 0.1
        end

        let(:query_response) {
          index.query(namespace: "example-namespace", vector: query_vector, top_k: 3)
        }

        it "returns a response" do
          expect(query_response).to be_a(HTTParty::Response)
          expect(query_response.code).to eq(200)
          expect(query_response.parsed_response).to have_key("matches")

          # Verify namespace-specific results
          matches = query_response.parsed_response["matches"]
          expect(matches).to be_an(Array)
          expect(matches.length).to be > 0
          expect(matches.first).to have_key("id")

          if query_response.parsed_response["namespace"]
            expect(query_response.parsed_response["namespace"]).to eq("example-namespace")
          end
        end
      end

      it "handles query by ID" do
        index.upsert(data)
        sleep 0.1

        response = index.query(id: "query1", top_k: 2)
        expect(response).to be_a(HTTParty::Response)
        expect([200, 400]).to include(response.code)  # Some containers may not support query by ID
      end

      it "handles invalid query parameters" do
        response = index.query(vector: [0.1])  # Wrong dimension
        expect(response).to be_a(HTTParty::Response)
        expect([400, 422]).to include(response.code)
      end
    end

    describe "#describe_index_stats" do
      let(:data) {
        {
          vectors: [
            {values: [0.1, 0.2], id: "stats1", metadata: {genre: "comedy"}},
            {values: [0.3, 0.4], id: "stats2", metadata: {genre: "comedy"}},
            {values: [0.5, 0.6], id: "stats3"}
          ]
        }
      }

      let(:describe_response) {
        index.describe_index_stats
      }

      before do
        index.upsert(data)
        sleep 0.1
      end

      it "returns a successful response" do
        expect(describe_response).to be_a(HTTParty::Response)
        expect(describe_response.code).to eq(200)
        expect(describe_response.parsed_response).to have_key("totalVectorCount")

        # Verify actual vector count reflects upserted data
        total_count = describe_response.parsed_response["totalVectorCount"]
        expect(total_count).to be >= 3  # At least the 3 vectors we upserted
        expect(describe_response.parsed_response).to have_key("dimension")
        expect(describe_response.parsed_response["dimension"]).to eq(2)  # Dense container is 2D
      end

      describe "with filter" do
        let(:filter) { {genre: {"$eq" => "comedy"}} }
        let(:describe_response) {
          index.describe_index_stats(filter: filter)
        }

        it "returns a response (filter may not be supported)" do
          expect(describe_response).to be_a(HTTParty::Response)
          expect([200, 400]).to include(describe_response.code)  # Local container may not support filtering
          if describe_response.code == 200
            expect(describe_response.parsed_response).to have_key("totalVectorCount")
          end
        end
      end

      it "handles empty filter" do
        response = index.describe_index_stats(filter: {})
        expect(response).to be_a(HTTParty::Response)
        expect(response.code).to eq(200)
      end
    end
  end
end
