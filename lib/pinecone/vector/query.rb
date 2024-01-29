# frozen_string_literal: true

require "dry-struct"
require "dry-validation"

require "pinecone/vector/filter"
require "pinecone/vector/sparse_vector"

module Types
  include Dry.Types()
end

module Pinecone
  class Vector
    class Query < Dry::Struct
      class QueryContract < Dry::Validation::Contract
        params do
          optional(:vector).filled(:array)
          optional(:id).filled(:string)
        end

        rule(:vector, :id) do
          if !values[:vector].nil? && !values[:id].nil?
            key(:vector).failure("Only one of vector or id can be specified")
            key(:id).failure("Only one of vector or id can be specified")
          end
        end
      end

      schema schema.strict

      attribute :namespace, Dry::Types["string"].default("")
      attribute :include_values, Dry::Types["bool"].default(false)
      attribute :include_metadata, Dry::Types["bool"].default(true)
      attribute :top_k, Dry::Types["integer"].default(10)
      attribute? :vector, Dry::Types["array"].of(Dry::Types["float"] | Dry::Types["integer"])
      # Disabled contract since it wasn't carrying forward attributes to to_json
      # See failing test in query_spec.rb
      # attribute? :filter, Filter
      attribute? :filter, Dry::Types["hash"]
      attribute? :sparse_vector, SparseVector
      attribute? :id, Dry::Types["string"]

      def self.new(input)
        validation = QueryContract.new.call(input)
        if validation.success?
          super(input)
        else
          raise ArgumentError.new(validation.errors.to_h.inspect)
        end
      end

      def to_json
        to_h.map do |key, value|
          [key.to_s.split("_").map.with_index do |word, index|
            (index == 0) ? word : word.capitalize
          end.join.to_sym, value]
        end.to_h.to_json
      end
    end
  end
end
