require "spec_helper"

RSpec.describe Pinecone do
  it "has a version number" do
    expect(Pinecone::VERSION).not_to be nil
  end

  describe "#configure" do
    let(:api_key) { "abc123" }
    let(:environment) { "def456" }

    before do
      Pinecone.configure do |config|
        config.api_key = api_key
        config.environment = environment
      end
    end

    it "returns the config" do
      expect(Pinecone.configuration.api_key).to eq(api_key)
      expect(Pinecone.configuration.environment).to eq(environment)
    end

    context "without an api key" do
      let(:api_key) { nil }

      it "raises an error" do
        expect {
          Pinecone::Client.new.list_indexes
        }.to raise_error(Pinecone::ConfigurationError)

        # reset the configuration
        Pinecone.configure do |config|
          config.api_key = "foo"
        end
      end
    end
  end
end
