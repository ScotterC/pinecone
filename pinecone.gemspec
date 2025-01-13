require_relative "lib/pinecone/version"

Gem::Specification.new do |s|
  s.name = "pinecone"
  s.version = Pinecone::VERSION
  s.summary = "Ruby client library for Pinecone Vector DB"
  s.description = "Ruby client library which includes index and vector operations to upload embeddings into Pinecone and do similarity searches on them."
  s.authors = ["Scott Carleton"]
  s.email = "scott@extrayarn.com"
  s.files = Dir["lib/pinecone.rb", "lib/pinecone/**/*.rb"]
  s.homepage = "https://rubygems.org/gems/pinecone"
  s.metadata = {"source_code_uri" => "https://github.com/ScotterC/pinecone"}
  s.license = "MIT"
  s.required_ruby_version = ">= 3"

  s.add_dependency "httparty", "~> 0.22.0"
  s.add_dependency "dry-struct", "~> 1.6"
  s.add_dependency "dry-validation", "~> 1.10"
end
