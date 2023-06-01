# The test suite only supports the index `example-index-b2e8921` that I don't have access to.
# So I'm creating this script to test `index.delete(filter:{})`
#
# Usage:
#   Make sure that you have at least one index on pinecone.
#   You can run `bundle exec ruby spec/support/setup.rb start` to create one.
#
#   You can then run this script:
#   $> bundle exec ruby spec/custom_test.rb
#
require 'bundler/setup'
Bundler.setup
require "pinecone"
require "dotenv/load"

Pinecone.configure do |config|
  config.api_key  = ENV.fetch('PINECONE_API_KEY')
  config.environment = ENV.fetch('PINECONE_ENVIRONMENT')
end

pinecone = Pinecone::Client.new
pp indexes = pinecone.list_indexes

puts "First index:"
pp index = pinecone.index(indexes.first)
puts ""

vectors = [
  { id: "doc:1/chunk:1", metadata: { original_id: "doc:1", type: "document" }, values: [ 0.1, 0.2, 0.0 ] },
  { id: "doc:1/chunk:2", metadata: { original_id: "doc:1", type: "document" }, values: [ 0.2, 0.3, 0.0 ] },
  { id: "doc:2/chunk:1", metadata: { original_id: "doc:2", type: "document" }, values: [ 0.1, 0.2, 0.0 ] },
  { id: "doc:2/chunk:2", metadata: { original_id: "doc:2", type: "document" }, values: [ 0.2, 0.3, 0.0 ] },
  { id: "doc:3/chunk:1", metadata: { original_id: "doc:3", type: "document" }, values: [ 0.1, 0.2, 0.0 ] },
]

puts "Upserting..."
index.upsert(
  namespace: "example-namespace",
  vectors: vectors
)
puts "Done"
puts ""

puts "Vectors for all documents:"
pp index.fetch(
  ids: vectors.map { _1.fetch(:id) },
  namespace: "example-namespace"
)
puts ""

puts "Deleting vectors for doc:1:"
pp index.delete(
  filter: { original_id: "doc:1" },
  namespace: "example-namespace"
)
puts "Done"
puts ""

puts "Vectors for all documents:"
pp index.fetch(
  ids: vectors.map { _1.fetch(:id) },
  namespace: "example-namespace"
)
puts ""

# Output is:
# ["example-index-1"]
# First index:
# #<Pinecone::Vector:0x00007fc57c297018
#  @base_uri="https://example-index-1-8006484.svc.<concealed by 1Password>.pinecone.io",
#  @headers=
#   {"Content-Type"=>"application/json",
#    "Accept"=>"application/json",
#    "Api-Key"=>"<concealed by 1Password>"}>
#
# Upserting...
# Done
#
# Vectors for all documents:
# {"vectors"=>
#   {"doc:3/chunk:1"=>
#     {"id"=>"doc:3/chunk:1",
#      "values"=>[0.1, 0.2, 0],
#      "metadata"=>{"original_id"=>"doc:3", "type"=>"document"}},
#    "doc:2/chunk:1"=>
#     {"id"=>"doc:2/chunk:1",
#      "values"=>[0.1, 0.2, 0],
#      "metadata"=>{"original_id"=>"doc:2", "type"=>"document"}},
#    "doc:1/chunk:1"=>
#     {"id"=>"doc:1/chunk:1",
#      "values"=>[0.1, 0.2, 0],
#      "metadata"=>{"original_id"=>"doc:1", "type"=>"document"}},
#    "doc:2/chunk:2"=>
#     {"id"=>"doc:2/chunk:2",
#      "values"=>[0.2, 0.3, 0],
#      "metadata"=>{"original_id"=>"doc:2", "type"=>"document"}},
#    "doc:1/chunk:2"=>
#     {"id"=>"doc:1/chunk:2",
#      "values"=>[0.2, 0.3, 0],
#      "metadata"=>{"original_id"=>"doc:1", "type"=>"document"}}},
#  "namespace"=>"example-namespace"}
#
# Deleting vectors for doc:1:
# {}
# Done
#
# Vectors for all documents:
# {"vectors"=>
#   {"doc:2/chunk:2"=>
#     {"id"=>"doc:2/chunk:2",
#      "values"=>[0.2, 0.3, 0],
#      "metadata"=>{"original_id"=>"doc:2", "type"=>"document"}},
#    "doc:2/chunk:1"=>
#     {"id"=>"doc:2/chunk:1",
#      "values"=>[0.1, 0.2, 0],
#      "metadata"=>{"original_id"=>"doc:2", "type"=>"document"}},
#    "doc:3/chunk:1"=>
#     {"id"=>"doc:3/chunk:1",
#      "values"=>[0.1, 0.2, 0],
#      "metadata"=>{"original_id"=>"doc:3", "type"=>"document"}}},
#  "namespace"=>"example-namespace"}
