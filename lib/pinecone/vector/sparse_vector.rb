# frozen_string_literal: true

require "dry-struct"
require "dry-validation"

module Types
  include Dry.Types()
end

module Pinecone
  class Vector
    class SparseVector < Dry::Struct
      class SparseVectorContract < Dry::Validation::Contract
        params do
          required(:indices).filled(:array)
          required(:values).filled(:array)
        end

        rule(:indices, :values) do
          unless values[:indices].size === values[:values].size
            key(:indices).failure("Indices and values must be the same size")
            key(:values).failure("Indices and values must be the same size")
          end
        end
      end

      attribute :indices, Dry::Types["array"].of(Dry::Types["integer"])
      attribute :values, Dry::Types["array"].of(Dry::Types["float"] | Dry::Types["integer"])

      def self.new(input)
        validation = SparseVectorContract.new.call(input)
        if validation.success?
          super(input)
        else
          raise ArgumentError.new(validation.errors.to_h.inspect)
        end
      end
    end
  end
end
