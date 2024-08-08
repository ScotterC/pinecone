require "spec_helper"

RSpec.describe Pinecone::Vector do
  let(:index) {
    VCR.use_cassette("use_serverless_index") do
      Pinecone::Vector.new("serverless-index")
    end
  }

  after :each do
    index.delete(delete_all: true)
  end

  describe "#upsert", :vcr do
    let(:data) { {vectors: [{values: [1, 2, 3], id: "1"}]} }

    describe "successful response" do
      let(:upsert_response) {
        index.upsert(data)
      }

      it "returns a response" do
        expect(upsert_response).to be_a(HTTParty::Response)
        expect(upsert_response.code).to eq(200)
        expect(upsert_response.parsed_response).to eq({"upsertedCount" => 1})
      end
    end

    describe "unsuccessful response" do
      let(:upsert_response) {
        index.upsert("foo")
      }

      it "returns a response" do
        expect(upsert_response).to be_a(HTTParty::Response)
        expect(upsert_response.code).to eq(400)
        expect(upsert_response.parsed_response).to eq(": Root element must be a message.")
      end
    end
  end

  describe "#delete", :vcr do
    let(:index) {
      VCR.use_cassette("use_server_index") do
        Pinecone::Vector.new("server-index") # delete by filter requires server index
      end
    }
    let(:data) { {vectors: [{values: [1, 2, 3], id: "5"}]} }

    describe "successful response" do
      let(:delete_response) {
        index.delete(ids: ["5"])
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
        index.upsert(data)
        expect(delete_response).to be_a(HTTParty::Response)
        expect(delete_response.code).to eq(200)
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

  describe "#fetch", :vcr do
    describe "successful response" do
      let(:fetch_response) {
        index.fetch(ids: ["1", "2"])
      }

      it "returns a response" do
        index.upsert({vectors: [{values: [1, 2, 3], id: "1"}]})
        index.upsert({vectors: [{values: [1, 2, 3], id: "2"}]})
        wait_for_upsert_completion(expected_count: 2)
        expect(fetch_response).to be_a(HTTParty::Response)
        expect(fetch_response.code).to eq(200)
        expect(fetch_response.parsed_response).to match(
          "namespace" => "",
          "vectors" => {
            "1" => {
              "id" => "1",
              "values" => [1, 2, 3]
            },
            "2" => {
              "id" => "2",
              "values" => [1, 2, 3]
            }
          },
          "usage" => {"readUnits" => 1}
        )
      end
    end
  end

  describe "#list", :vcr do
    let(:data) {
      {
        vectors: [
          {values: [1, 2, 3], id: "test1"},
          {values: [4, 5, 6], id: "test2"},
          {values: [7, 8, 9], id: "test3"},
          {values: [10, 11, 12], id: "other1"}
        ]
      }
    }

    before do
      index.upsert(data)
      wait_for_upsert_completion(expected_count: 4)
    end

    context "without a block" do
      it "returns all IDs" do
        result = index.list
        expect(result).to match_array(["test1", "test2", "test3", "other1"])
      end

      it "respects the limit parameter" do
        result = index.list(limit: 2)
        expect(result.length).to eq(2)
        expect(["test1", "test2", "test3", "other1"]).to include(*result)
      end

      it "filters by prefix" do
        result = index.list(prefix: "test")
        expect(result).to match_array(["test1", "test2", "test3"])
      end

      it "respects namespace" do
        index.upsert(vectors: [{values: [13, 14, 15], id: "ns1"}], namespace: "example-namespace")
        wait_for_upsert_completion(expected_count: 5)

        result = index.list(namespace: "example-namespace")
        expect(result).to eq(["ns1"])
      end
    end

    context "with a block" do
      it "yields batches of IDs" do
        yielded_ids = []
        index.list do |batch|
          yielded_ids.concat(batch)
        end
        expect(yielded_ids).to match_array(["test1", "test2", "test3", "other1"])
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
        expect(yielded_ids).to match_array(["test1", "test2", "test3"])
      end

      it "respects namespace" do
        index.upsert(vectors: [{values: [13, 14, 15], id: "ns1"}], namespace: "example-namespace")
        wait_for_upsert_completion(expected_count: 5)

        yielded_ids = []
        index.list(namespace: "example-namespace") do |batch|
          yielded_ids.concat(batch)
        end
        expect(yielded_ids).to eq(["ns1"])
      end
    end

    context "with more than 100 vectors" do
      before do
        additional_data = {
          vectors: 150.times.map do |i|
            {values: [i, i + 1, i + 2], id: "extra#{i}"}
          end
        }

        # Upsert the additional vectors in a single call
        index.upsert(additional_data)
        wait_for_upsert_completion(expected_count: 154)  # 4 original + 150 new
      end

      it "returns all vectors when no limit is specified" do
        result = index.list
        expect(result.length).to eq(154)
      end

      it "respects a limit larger than 100" do
        result = index.list(limit: 150)
        expect(result.length).to eq(150)
      end

      it "returns all vectors when limit is greater than total count" do
        result = index.list(limit: 200)
        expect(result.length).to eq(154)
      end

      context "with a block" do
        it "yields all vectors when no limit is specified" do
          yielded_ids = []
          index.list do |batch|
            yielded_ids.concat(batch)
          end
          expect(yielded_ids.length).to eq(154)
        end

        it "respects a limit larger than 100" do
          yielded_ids = []
          index.list(limit: 150) do |batch|
            yielded_ids.concat(batch)
          end
          expect(yielded_ids.length).to eq(150)
        end
      end
    end
  end

  describe "#list_paginated", :vcr do
    let(:index) {
      VCR.use_cassette("use_serverless_index") do
        Pinecone::Vector.new("serverless-index")
      end
    }

    let(:data) {
      {
        vectors: [
          {values: [1, 2, 3], id: "1"},
          {values: [1, 2, 3], id: "2"}
        ]
      }
    }

    describe "successful response" do
      let(:response) { index.list_paginated }

      before do
        index.upsert(data)
        wait_for_upsert_completion(expected_count: 2)
      end

      it "returns a response" do
        expect(response).to be_a(HTTParty::Response)
        expect(response.code).to eq(200)
        expect(response.parsed_response).to match(
          "namespace" => "",
          "vectors" => [
            {"id" => "1"},
            {"id" => "2"}
          ],
          "usage" => {"readUnits" => 1}
        )
      end
    end

    describe "success with prefix" do
      let(:data) {
        {
          vectors: [
            {values: [1, 2, 3], id: "foo#1"},
            {values: [1, 2, 3], id: "foo#2"},
            {values: [1, 2, 3], id: "bar#1"}
          ]
        }
      }

      let(:response) { index.list_paginated(prefix: "foo#") }

      before do
        index.upsert(data)
        wait_for_upsert_completion(expected_count: 3)
      end

      it "returns a response" do
        expect(response).to be_a(HTTParty::Response)
        expect(response.code).to eq(200)
        expect(response.parsed_response).to match(
          "namespace" => "",
          "vectors" => [
            {"id" => "foo#1"},
            {"id" => "foo#2"}
          ],
          "usage" => {"readUnits" => 1}
        )
      end
    end

    describe "success with limit" do
      let(:response) { index.list_paginated(limit: 1) }

      before do
        index.upsert(data)
        wait_for_upsert_completion(expected_count: 2)
      end

      it "returns a response" do
        expect(response).to be_a(HTTParty::Response)
        expect(response.code).to eq(200)
        expect(response.parsed_response).to match(
          "namespace" => "",
          "vectors" => [{"id" => "1"}],
          "pagination" => {"next" => be_a(String)},
          "usage" => {"readUnits" => 1}
        )
      end

      context "with more than 100 vectors" do
        before do
          additional_data = {
            vectors: 150.times.map do |i|
              {values: [i, i + 1, i + 2], id: "extra#{i}"}
            end
          }

          # Upsert the additional vectors in a single call
          index.upsert(additional_data)
          wait_for_upsert_completion(expected_count: 152)  # 4 original + 150 new
        end

        # API limit is 100
        it "returns all vectors when no limit is specified" do
          response = index.list_paginated(limit: 100)
          expect(response.parsed_response["vectors"].length).to eq(100)
        end
      end
    end

    describe "success with pagination token" do
      let(:pagination_token) { index.list_paginated(limit: 1).parsed_response.dig("pagination", "next") }
      let(:response) {
        index.list_paginated(limit: 1, pagination_token: pagination_token)
      }

      before do
        index.upsert(data)
        wait_for_upsert_completion(expected_count: 2)
      end

      it "returns a response" do
        expect(response).to be_a(HTTParty::Response)
        expect(response.code).to eq(200)
        expect(response.parsed_response).to match(
          "namespace" => "",
          "vectors" => [{"id" => "2"}],
          "usage" => {"readUnits" => 1}
        )
      end
    end
  end

  describe "#update", :vcr do
    describe "successful response" do
      let(:update_response) {
        index.update(id: "1", values: [1, 0, 3], set_metadata: {genre: "drama"})
      }

      it "returns a response" do
        index.upsert({vectors: [{values: [1, 2, 3], id: "1"}]})

        expect(update_response).to be_a(HTTParty::Response)
        expect(update_response.code).to eq(200)
        expect(update_response.parsed_response).to eq({})
      end
    end
  end

  describe "#query", :vcr do
    let(:data) {
      {
        vectors: [
          {values: [1, 2, 3], id: "1", metadata: {genre: "comedy"}},
          {values: [0, 1, -1], id: "2", metadata: {genre: "comedy"}},
          {values: [1, -1, 0], id: "3"}
        ]
      }
    }
    let(:query_vector) { [0.5, -0.5, 0] }

    describe "successful response" do
      before do
        index.upsert(data)
        wait_for_upsert_completion(expected_count: 3)
      end

      let(:query_response) {
        index.query(vector: query_vector)
      }

      let(:query_object) {
        Pinecone::Vector::Query.new(vector: query_vector)
      }

      let(:query_response_with_object) {
        index.query(query_object)
      }

      let(:valid_result) {
        {
          "results" => [],
          "matches" => [
            {
              "id" => "3",
              "score" => 1,
              "values" => []
            },
            {
              "id" => "2",
              "metadata" => {"genre" => "comedy"},
              "score" => -0.5,
              "values" => []
            },
            {
              "id" => "1",
              "metadata" => {"genre" => "comedy"},
              "score" => -0.5,
              "values" => []
            }
          ],
          "namespace" => "",
          "usage" => {"readUnits" => 6}
        }
      }

      it "returns a response" do
        expect(query_response).to be_a(HTTParty::Response)
        expect(query_response.parsed_response).to eq(valid_result)
      end

      it "returns a response when queried with object" do
        expect(query_response_with_object).to be_a(HTTParty::Response)
        expect(query_response_with_object.parsed_response).to eq(valid_result)
      end
    end

    describe "with filter" do
      before do
        index.upsert(data)
        wait_for_upsert_completion(expected_count: 3)
      end

      let(:valid_result) {
        {
          "results" => [],
          "matches" => [
            {
              "id" => "2",
              "metadata" => {"genre" => "comedy"},
              "score" => -0.5,
              "values" => []
            },
            {
              "id" => "1",
              "metadata" => {"genre" => "comedy"},
              "score" => -0.5,
              "values" => []
            }
          ],
          "namespace" => "",
          "usage" => {"readUnits" => 6}
        }
      }
      let(:filter) { {genre: {"$eq": "comedy"}} }
      let(:filter_response) { index.query(vector: query_vector, filter: filter) }

      it "returns a response" do
        expect(filter_response).to be_a(HTTParty::Response)
        expect(filter_response.code).to eq(200)
        expect(filter_response.parsed_response).to eq(valid_result)
      end
    end

    describe "with namespace" do
      let(:namespace) { "example-namespace" }

      before do
        index.upsert(data.merge(namespace: namespace))
        wait_for_upsert_completion(expected_count: 3)
      end

      let(:query_response) {
        index.query(namespace: "example-namespace", vector: query_vector)
      }

      it "returns a response" do
        expect(query_response).to be_a(HTTParty::Response)
        expect(query_response.parsed_response).to eq({
          "results" => [],
          "matches" => [
            {
              "id" => "3",
              "score" => 1,
              "values" => []
            },
            {
              "id" => "2",
              "metadata" => {"genre" => "comedy"},
              "score" => -0.5,
              "values" => []
            },
            {
              "id" => "1",
              "metadata" => {"genre" => "comedy"},
              "score" => -0.5,
              "values" => []
            }
          ],
          "namespace" => "example-namespace",
          "usage" => {"readUnits" => 6}
        })
      end
    end

    describe "missing index" do
      it "raises an exception" do
        VCR.use_cassette("missing_index") do
          expect { Pinecone::Vector.new("missing-index") }.to raise_error(Pinecone::IndexNotFoundError)
        end
      end
    end
  end

  describe "#describe_index_stats", :vcr do
    let(:index) {
      # Server required for metadata filtering
      VCR.use_cassette("use_server_index") do
        Pinecone::Vector.new("server-index")
      end
    }

    let(:data) {
      {
        vectors: [
          {values: [1, 2, 3], id: "1", metadata: {genre: "comedy"}},
          {values: [0, 1, -1], id: "2", metadata: {genre: "comedy"}},
          {values: [1, -1, 0], id: "3"}
        ]
      }
    }

    let(:describe_response) {
      index.describe_index_stats
    }

    before do
      index.upsert(data)
    end

    it "returns a successful response" do
      expect(describe_response).to be_a(HTTParty::Response)
      expect(describe_response.code).to eq(200)
      expect(describe_response.parsed_response).to eq({
        "namespaces" => {"" => {"vectorCount" => 3}},
        "dimension" => 3,
        "indexFullness" => 0,
        "totalVectorCount" => 3
      })
    end

    describe "with filter" do
      let(:filter) { {genre: {"$eq": "comedy"}} }
      let(:describe_response) {
        index.describe_index_stats(filter: filter)
      }

      it "returns a succesful response" do
        expect(describe_response).to be_a(HTTParty::Response)
        expect(describe_response.code).to eq(200)
        expect(describe_response.parsed_response).to eq({
          "namespaces" => {"" => {"vectorCount" => 2}},
          "dimension" => 3,
          "indexFullness" => 0,
          "totalVectorCount" => 3
        })
      end
    end
  end

  # Total Vector Count can take awhile
  def wait_for_upsert_completion(expected_count:)
    timeout = 20
    interval = 0.5
    Timeout.timeout(timeout) do
      loop do
        response = index.describe_index_stats
        break if response.parsed_response["totalVectorCount"] == expected_count
        sleep interval
      end
    end
  rescue Timeout::Error
    raise "Timed out waiting for upsert to complete"
  end
end
