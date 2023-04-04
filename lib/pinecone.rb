require "httparty"

require "pinecone/client"
require "pinecone/index"
require "pinecone/vector"
require "pinecone/collection"
require "pinecone/version"

module Pinecone
  class ConfigurationError < StandardError; end
  class IndexNotFoundError < StandardError; end
  class Configuration
    attr_writer :api_key, :base_uri, :environment

    def initialize
      @api_key     = nil
      @environment = nil
      @base_uri    = nil
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