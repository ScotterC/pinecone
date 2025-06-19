# frozen_string_literal: true

require "dry-struct"
require "dry-validation"

module Types
  include Dry.Types()

  StringOrNumberOrBoolean = Dry::Types["string"] | Dry::Types["integer"] | Dry::Types["float"] | Dry::Types["bool"]
  StringOrNumber = Dry::Types["string"] | Dry::Types["integer"] | Dry::Types["float"]
  Number = Dry::Types["integer"] | Dry::Types["float"]
end

module Pinecone
  class Vector
    class Filter < Dry::Struct
      class FilterContract < Dry::Validation::Contract
        schema do
          optional(:$and).filled(:array)
          optional(:$or).filled(:array)
          optional(:$eq).filled(Types::StringOrNumberOrBoolean)
          optional(:$ne).filled(Types::StringOrNumberOrBoolean)
          optional(:$gt).filled(Types::Number)
          optional(:$gte).filled(Types::Number)
          optional(:$lt).filled(Types::Number)
          optional(:$lte).filled(Types::Number)
          optional(:$in).filled(:array).each(Types::StringOrNumber)
          optional(:$nin).filled(:array).each(Types::StringOrNumber)
        end

        rule(:$and) do
          if key?
            key(:$and).failure("'$any' must be an array") unless value.is_a?(Array)

            value.each do |v|
              unless v.is_a?(Filter) || to_filter(v).is_a?(Filter)
                key(:$and).failure("'$any' must be an array of filters")
              end
            end
          end
        end

        rule(:$or) do
          if key?
            key(:$or).failure("'$or' must be an array") unless value.is_a?(Array)

            value.each do |v|
              unless v.is_a?(Filter) || to_filter(v).is_a?(Filter)
                key(:$or).failure("'$or' must be an array of filters")
              end
            end
          end
        end

        def to_filter(input)
          return false unless input.is_a?(Hash)

          Filter.new(input)
        end
      end

      def self.new(input)
        validation = FilterContract.new.call(input)
        raise ArgumentError, validation.errors.to_h.inspect unless validation.success?

        super
      end

      def self.default?
        nil
      end
    end
  end
end
