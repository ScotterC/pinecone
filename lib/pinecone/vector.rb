# frozen_string_literal: true

require "pinecone/vector/query"
require "pinecone/vector/filter"
require "pinecone/vector/sparse_vector"
require "json"

module Pinecone
  class Vector
    include HTTParty
    parser Pinecone::ResponseParser

    attr_reader :base_uri

    def initialize(index_name = nil, host: nil)
      if host
        # Direct host targeting (preferred)
        @base_uri = if host.start_with?("http://", "https://")
          host
        elsif host.start_with?("localhost")
          "http://#{host}" # Use HTTP for localhost
        else
          "https://#{host}" # Use HTTPS for production hosts
        end
      elsif index_name
        # Legacy path: call describe_index
        @base_uri = set_fallback_base_uri(index_name)
      else
        raise ArgumentError, "Must provide either index_name or host: parameter"
      end

      @headers = {
        "Content-Type" => "application/json",
        "Accept" => "application/json",
        "Api-Key" => Pinecone.configuration.api_key
      }
    end

    def delete(namespace: "", ids: [], delete_all: false, filter: {})
      inputs = {
        namespace: namespace,
        ids: ids,
        deleteAll: delete_all,
        filter: filter
      }
      inputs.delete(:filter) if delete_all || ids.any?
      payload = options.merge(body: inputs.to_json)
      self.class.post("#{@base_uri}/vectors/delete", payload)
    end

    def fetch(namespace: "", ids: [])
      query_string = URI.encode_www_form({namespace: namespace, ids: ids})
      self.class.get("#{@base_uri}/vectors/fetch?#{query_string}", options)
    end

    def list(prefix: nil, limit: nil, namespace: nil, &block)
      all_ids = []
      pagination_token = nil
      total_fetched = 0

      loop do
        current_limit = limit.nil? ? 100 : [limit - total_fetched, 100].min

        response = list_paginated(
          prefix: prefix,
          limit: current_limit,
          pagination_token: pagination_token,
          namespace: namespace
        )

        break unless response.success?

        results = response.parsed_response
        ids = results["vectors"]&.map { |v| v["id"] } || []

        if block
          yield ids
        else
          all_ids.concat(ids)
        end

        total_fetched += ids.length
        pagination_token = results.dig("pagination", "next")

        break if ids.empty?
        break if limit && total_fetched >= limit
        break if pagination_token.nil? || pagination_token.empty?
      end

      if block
        nil
      else
        limit ? all_ids.first(limit) : all_ids
      end
    end

    def list_paginated(prefix: nil, limit: nil, pagination_token: nil, namespace: nil)
      query_params = {}
      query_params["prefix"] = prefix if prefix
      query_params["limit"] = limit if limit
      query_params["paginationToken"] = pagination_token if pagination_token
      query_params["namespace"] = namespace if namespace

      query_string = URI.encode_www_form(query_params)
      self.class.get("#{@base_uri}/vectors/list?#{query_string}", options)
    end

    def upsert(body)
      payload = options.merge(body: body.to_json)
      self.class.post("#{@base_uri}/vectors/upsert", payload)
    end

    def query(query)
      object = query.is_a?(Pinecone::Vector::Query) ? query : Pinecone::Vector::Query.new(query)
      payload = options.merge(body: object.to_json)
      self.class.post("#{@base_uri}/query", payload)
    end

    def update(id:, values: [], sparse_values: {indices: [], values: []}, set_metadata: {}, namespace: "")
      inputs = {
        id: id
      }
      inputs["values"] = values unless values.empty?
      inputs["sparseValues"] = sparse_values unless sparse_values[:indices].empty? || sparse_values[:values].empty?
      inputs["setMetadata"] = set_metadata unless set_metadata.empty?
      inputs["namespace"] = namespace unless namespace.empty?

      payload = options.merge(body: inputs.to_json)
      self.class.post("#{@base_uri}/vectors/update", payload)
    end

    def describe_index_stats(filter: {})
      payload = if filter.empty?
        options.merge(body: {}.to_json)
      else
        options.merge(body: {filter: filter}.to_json)
      end
      self.class.post("#{@base_uri}/describe_index_stats", payload)
    end

    def options
      {
        headers: @headers
      }
    end

    private

    # https://index_name-project_id.svc.environment.pinecone.io
    def set_fallback_base_uri(index_name)
      index_description = Pinecone::Index.new.describe(index_name)
      raise Pinecone::IndexNotFoundError, "Index #{index_name} does not exist" if index_description.code != 200

      uri = index_description.parsed_response["host"]
      "https://#{uri}"
    end
  end
end
