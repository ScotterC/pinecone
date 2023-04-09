Gem::Specification.new do |s|
  s.name        = "pinecone"
  s.version     = "0.1.2"
  s.summary     = "Ruby client library for Pinecone Vector DB"
  s.description = "Ruby client library which includes index and vector operations to upload embeddings into Pinecone and do similarity searches on them."
  s.authors     = ["Scott Carleton", "Lauri Jutila"]
  s.email       = ["scott@extrayarn.com", "git@laurijutila.com"]
  s.files       = ["lib/pinecone.rb"]
  s.homepage    = "https://rubygems.org/gems/pinecone"
  s.metadata    = {"source_code_uri" => "https://github.com/ScotterC/pinecone"}
  s.license     = "MIT"

  s.add_dependency "dotenv", "~> 2.8"
  s.add_dependency "httparty", "~> 0.21.0"
  s.add_dependency "dry-struct", "~> 1.5.0"
  s.add_dependency "dry-validation"

  s.add_development_dependency "awesome_print"
  s.add_development_dependency "rake", "~> 13.0"
  s.add_development_dependency "debug", "~> 1.7"
  s.add_development_dependency "rspec", "~> 3.12"
  s.add_development_dependency "webmock", "~> 3.14"
  s.add_development_dependency "vcr", "~> 6.1"
end