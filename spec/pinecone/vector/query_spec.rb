require "spec_helper"

module Pinecone
  RSpec.describe Vector::Query do
    describe "Defaults" do
      let(:vector) { [0, 0.5, -0.5] }
      let(:query) { described_class.new(vector: vector) }

      it "has a default namespace" do
        expect(query.namespace).to eq("")
      end

      it "has a default include_values" do
        expect(query.include_values).to eq(false)
      end

      it "has a default include_metadata" do
        expect(query.include_metadata).to eq(true)
      end

      it "has a default top_k" do
        expect(query.top_k).to eq(10)
      end
    end

    describe "Validations" do
      context "when vector and id are both specified" do
        let(:vector) { [0, 0.5, -0.5] }
        let(:query) { described_class.new(vector: vector, id: "foo") }

        it "raises an error" do
          expect{ query }.to raise_error(ArgumentError)
        end
      end
    end

    describe "Vector" do
      context "must be an array of floats and/or integers" do
        let(:vector) { [0, 0.5, -0.5] }
        let(:query) { described_class.new(vector: vector) }

        it "is valid" do
          expect{ query }.not_to raise_error
          expect(query.vector).to eq(vector)
        end

        context "all integers" do
          let(:vector) { [0, 1, -1] }

          it { expect{ query }.not_to raise_error }
        end

        context "all floats" do
          let(:vector) { [0.0, 0.5, -0.5] }

          it { expect{ query }.not_to raise_error }          
        end

        context "with a non-numeric value" do
          let(:vector) { [0, 0.5, "foo"] }

          it "raises an error" do
            expect { query }.to raise_error(Dry::Struct::Error)
          end
        end
      end
    end

    describe "#to_h" do
      let(:vector) { [0, 0.5, -0.5] }
      let(:query) { described_class.new(vector: vector) }

      it "returns a hash" do
        expect(query.to_h).to eq({
          namespace: "",
          include_values: false,
          include_metadata: true,
          top_k: 10,
          vector: [0, 0.5, -0.5]
        })
      end
    end
  end
end