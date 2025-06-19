# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pinecone::Client do
  let(:client) { Pinecone::Client.new }

  describe "#index" do
    it "allows multiple indices" do
      index_1 = client.index(host: "serverless-index-abc123.svc.us-east1.pinecone.io")
      index_2 = client.index(host: "server-index-def456.svc.us-west1.pinecone.io")

      expect(index_1.base_uri).to match(/serverless-index/)
      expect(index_2.base_uri).to match(/server-index/)
    end

    context "host parameter functionality" do
      it "creates index with direct host" do
        index = client.index(host: "example.com")
        expect(index.base_uri).to eq("https://example.com")
      end

      it "handles host with https prefix" do
        index = client.index(host: "https://example.com")
        expect(index.base_uri).to eq("https://example.com")
      end

      it "uses http for localhost" do
        index = client.index(host: "localhost:5081")
        expect(index.base_uri).to eq("http://localhost:5081")
      end

      it "handles http prefix explicitly" do
        index = client.index(host: "http://localhost:5081")
        expect(index.base_uri).to eq("http://localhost:5081")
      end

      it "uses global host when configured" do
        # Temporarily set global host
        original_host = Pinecone.configuration.host
        Pinecone.configuration.host = "global-host.com"

        index = client.index
        expect(index.base_uri).to eq("https://global-host.com")

        # Reset
        Pinecone.configuration.host = original_host
      end

      it "overrides global host with explicit parameter" do
        # Temporarily set global host
        original_host = Pinecone.configuration.host
        Pinecone.configuration.host = "global-host.com"

        index = client.index(host: "override-host.com")
        expect(index.base_uri).to eq("https://override-host.com")

        # Reset
        Pinecone.configuration.host = original_host
      end

      it "raises error when no host provided" do
        # Ensure no global host is set
        original_host = Pinecone.configuration.host
        Pinecone.configuration.host = nil

        expect { client.index }.to raise_error(ArgumentError, /No host provided/)

        # Reset
        Pinecone.configuration.host = original_host
      end
    end

    context "deprecation warnings" do
      it "shows deprecation warning for string argument" do
        # Only test deprecation warnings in non-container environment
        skip "Deprecation test not applicable in container environment" if database_available?

        # Temporarily enable warnings for this test
        Pinecone.configuration.silence_deprecation_warnings = false

        # Mock the Vector.new call to avoid API calls
        allow(Pinecone::Vector).to receive(:new).and_return(double("vector"))

        expect { client.index("test-index") }.to output(/DEPRECATED/).to_stderr

        # Reset to silenced for other tests
        Pinecone.configuration.silence_deprecation_warnings = true
      end
    end
  end
end
