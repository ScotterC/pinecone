# frozen_string_literal: true

require "spec_helper"

module Pinecone
  RSpec.describe Vector::Filter do
    describe "Validations" do
      context "when $and is specified" do
        let(:filter) { described_class.new("$and": [{ "genre": "comedy" }, { "genre": "drama" }]) }
        let(:invalid_filter) { described_class.new("$and": [1, 2, 3]) }

        it "raises an error" do
          expect{ invalid_filter }.to raise_error(ArgumentError)
        end

        it "does not raise error with valid filter" do
          expect{ filter }.not_to raise_error
        end
      end

      context "when $or is specified" do
        let(:filter) { described_class.new("$or": [{ "genre": "comedy" }, { "genre": "drama" }]) }
        let(:invalid_filter) { described_class.new("$or": [1, "foo", 3]) }

        it "raises an error" do
          expect{ invalid_filter }.to raise_error(ArgumentError)
        end

        it "does not raise error with valid filter" do
          expect{ filter }.not_to raise_error
        end
      end

      context "when $eq is specified" do
        let(:filter) { described_class.new("$eq": 1) }
        let(:invalid_filter) { described_class.new("$eq": ["foo", "bar"]) }

        it "does not raise an error with a valid filter" do
          expect{ filter }.not_to raise_error
        end

        it "raises an error with an invalid filter" do
          expect{ invalid_filter }.to raise_error(ArgumentError)
        end
      end

      context "when $ne is specified" do
        let(:filter) { described_class.new("$ne": 1) }
        let(:invalid_filter) { described_class.new("$ne": ["foo", "bar"]) }

        it "does not raise an error with a valid filter" do
          expect{ filter }.not_to raise_error
        end

        it "raises an error with an invalid filter" do
          expect{ invalid_filter }.to raise_error(ArgumentError)
        end
      end

      [ "$lt", "$lte", "$gt", "$gte" ].each do |operator|
        context "when #{operator} is specified" do
          let(:filter) { described_class.new("#{operator}": 1) }
          let(:filter_2) { described_class.new("#{operator}": 1.5) }
          let(:invalid_filter) { described_class.new("#{operator}": ["foo", "bar"]) }
          let(:invalid_filter_2) { described_class.new("#{operator}": "foo") }
  
          it "does not raise an error with a valid filter" do
            expect{ filter }.not_to raise_error
            expect{ filter_2 }.not_to raise_error
          end
  
          it "raises an error with an invalid filter" do
            expect{ invalid_filter }.to raise_error(ArgumentError)
            expect{ invalid_filter_2 }.to raise_error(ArgumentError)
          end
        end
      end

      context "when $in is specified" do
        let(:filter) { described_class.new("$in": [1, "foo", 3]) }
        let(:invalid_filter) { described_class.new("$in": "foo") }
        let(:invalid_filter_2) { described_class.new("$in": [1, true, "bar"]) }

        it "does not raise an error with a valid filter" do
          expect{ filter }.not_to raise_error
        end

        it "raises an error with an invalid filter" do
          expect{ invalid_filter }.to raise_error(ArgumentError)
          expect{ invalid_filter_2 }.to raise_error(ArgumentError)
        end
      end

      context "when $nin is specified" do
        let(:filter) { described_class.new("$nin": [1, "foo", 3]) }
        let(:invalid_filter) { described_class.new("$nin": "foo") }
        let(:invalid_filter_2) { described_class.new("$nin": [1, true, "bar"]) }

        it "does not raise an error with a valid filter" do
          expect{ filter }.not_to raise_error
        end

        it "raises an error with an invalid filter" do
          expect{ invalid_filter }.to raise_error(ArgumentError)
          expect{ invalid_filter_2 }.to raise_error(ArgumentError)
        end
      end
    end
  end
end