# frozen_string_literal: true

require "httparty"

require "pinecone/response_parser"
require "pinecone/client"
require "pinecone/index"
require "pinecone/vector"
require "pinecone/collection"
require "pinecone/version"

module Pinecone
  class ConfigurationError < StandardError; end

  class IndexNotFoundError < StandardError; end

  class Configuration
    attr_writer :api_key, :base_uri, :environment, :silence_deprecation_warnings
    attr_accessor :host

    def initialize
      @api_key = nil
      @environment = nil
      @base_uri = nil
      @host = nil
      @silence_deprecation_warnings = false
    end

    def api_key
      return @api_key if @api_key

      raise ConfigurationError, "Pinecone API key not set"
    end

    def base_uri
      return @base_uri if @base_uri

      raise ConfigurationError, "Pinecone domain not set"
    end

    def environment
      return @environment if @environment

      raise ConfigurationError, "Pinecone environment not set"
    end

    def silence_deprecation_warnings?
      @silence_deprecation_warnings
    end
  end

  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Pinecone::Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end
