Gem::Specification.new do |s|
  s.name        = "pinecone"
  s.version     = "0.1.2"
  s.summary     = "Ruby client library for Pinecone Vector DB"
  s.description = "Ruby client library which includes index and vector operations to upload embeddings into Pinecone and do similarity searches on them."
  s.authors     = ["Scott Carleton"]
  s.email       = "scott@extrayarn.com"
  s.files       = ["lib/pinecone.rb"]
  s.homepage    = "https://rubygems.org/gems/pinecone"
  s.metadata    = {"source_code_uri" => "https://github.com/ScotterC/pinecone"}
  s.license     = "MIT"
  s.add_runtime_dependency "httparty", "~> 0.21.0"
end
