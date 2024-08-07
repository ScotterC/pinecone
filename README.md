# Pinecone Ruby Client
[![Gem Version](https://badge.fury.io/rb/pinecone.svg)](https://badge.fury.io/rb/pinecone)
![GitHub](https://img.shields.io/github/license/scotterc/pinecone)

[Ruby AI Builders Discord](https://discord.gg/k4Uc224xVD)

This is the complete Pinecone API and fully tested. Bug reports and contributions are welcome!

## Installation

`gem install pinecone`

## Configuration

```ruby
require "dotenv/load"
require 'pinecone'

Pinecone.configure do |config|
  config.api_key  = ENV.fetch('PINECONE_API_KEY')
  config.environment = ENV.fetch('PINECONE_ENVIRONMENT')
end
```

## Index Operations

Listing Indexes
```ruby
pinecone = Pinecone::Client.new
pinecone.list_indexes
```

Describe Index
```ruby
pinecone.describe_index("example-index")
```

Create Index
```ruby
pinecone.create_index({
  "metric": "dotproduct",
  "name": "example-index",
  "dimension": 3,
  "spec": {
        "pod": {
          "environment": "gcp-starter",
          "pod_type": "starter"
        }
      }
})
```

Delete Index
```ruby
pinecone.delete_index("example-index")
```

Scale replicas
```ruby
new_number_of_replicas = 4
pinecone.configure_index("example-index", {
  replicas: new_number_of_replicas
  pod_type: "s1.x1"
})
```

## Vector Operations

Adding vectors to an existing index

```ruby
pinecone = Pinecone::Client.new
index = pinecone.index("example-index")

index.upsert(
  namespace: "example-namespace",
  vectors: [{
    id: "1",
    metadata: {
      key: value
    },
    values: [
      0.1,
      0.2,
      0.0
    ]
  }]
)
```

Querying index with a vector
```ruby
pinecone = Pinecone::Client.new
index = pinecone.index("example-index")
embedding = [0.0, -0.2, 0.4]
response = index.query(vector: embedding)
```

Querying index with options
```ruby
pinecone = Pinecone::Client.new
index = pinecone.index("example-index")
embedding = [0.0, -0.2, 0.4]
response = index.query(vector: embedding, 
                        namespace: "example-namespace",
                        top_k: 10,
                        include_values: false,
                        include_metadata: true)
```

Fetching a vector from an index
```ruby
pinecone = Pinecone::Client.new
index = pinecone.index("example-index")
index.fetch(
  ids: ["1"], 
  namespace: "example-namespace"
)
```

List vector IDs from an index (only for serverless indexes)
```ruby
pinecone = Pinecone::Client.new
index = pinecone.index("example-index")
index.list(
  namespace: "example-namespace",
  prefix: "example-prefix",
  limit: 50,
  pagination_token: "example-token"
)
```

Updating a vector in an index
```ruby
pinecone = Pinecone::Client.new
index = pinecone.index("example-index")
index.update(
  id: "1", 
  values: [0.1, -0.2, 0.0],
  set_metadata: { genre: "drama" },
  namespace: "example-namespace"
)
```

Deleting a vector from an index

Note, that only one of `ids`, `delete_all` or `filter` can be included. If `ids` are present or `delete_all: true` then the filter is removed from the request.
```ruby
pinecone = Pinecone::Client.new
index = pinecone.index("example-index")
index.delete(
  ids: ["1"], 
  namespace: "example-namespace", 
  delete_all: false,
  filter: {
    "genre": { "$eq": "comedy" }
  }
)
```

Describe index statistics. Can be filtered - see Filtering queries
```ruby
pinecone = Pinecone::Client.new
index = pinecone.index("example-index")
index.describe_index_stats(
  filter: {
    "genre": { "$eq": "comedy" }
  }
)
```

### Filtering queries

Add a `filter` option to apply filters to your query. You can use vector metadata to limit your search. See [metadata filtering](https://www.pinecone.io/docs/metadata-filtering/) in Pinecode documentation.

```ruby
pinecone = Pinecone::Client.new
index = pinecone.index("example-index")
embedding = [0.0, -0.2, 0.4]
response = index.query(
  vector: embedding,
  filter: {
    "genre": { "$eq": "comedy" }
  }
)
```

Metadata filters can be combined with AND and OR. Other operators are also supported.

```ruby
{ "$and": [{ "genre": "comedy" }, { "actor": "Brad Pitt" }] } # Genre is 'comedy' and actor is 'Brad Pitt'
{ "$or": [{ "genre": "comedy" }, { "genre": "action" }] } # Genre is 'comedy' or 'action'
{ "genre": { "$eq": "comedy" }} # Genre is 'comedy'
{ "favorite": { "$eq": true }} # Is a favorite
{ "genre": { "$ne": "comedy" }} # Genre is not 'comedy'
{ "favorite": { "$ne": true }} # Is not a favorite
{ "genre": { "$in": ["comedy", "action"] }} # Genre is in the specified values
{ "genre": { "$nin": ["comedy", "action"] }} # Genre is not in the specified values
{ "$gt": 1 }
{ "$gte": 0.5 }
{ "$lt": -0.5 }
{ "$lte": -1 }
```

Specifying an invalid filter raises `ArgumentError` with an error message.

### Sparse Vectors

```ruby
pinecone = Pinecone::Client.new
index = pinecone.index("example-index")
embedding = [0.0, -0.2, 0.4]
response = index.query(
  vector: embedding,
  sparse_vector: {
    indices: [10, 20, 30],
    values: [0, 0.5, -1]
  }
)
```

The length of indices and values must match.

### Query by ID

```ruby
pinecone = Pinecone::Client.new
index = pinecone.index("example-index")
embedding = [0.0, -0.2, 0.4]
response = index.query(
  id: "vector1"
)
```

Either `vector` or `id` can be supplied as a query parameter, not both. This constraint is validated.

## Collection Operations

Creating a collection
```ruby
pinecone = Pinecone::Client.new
pinecone.create_collection({
  name: "example-collection", 
  source: "example-index"
})
```

List collections
```ruby
pinecone.list_collections
```

Describe a collection
```ruby
pinecone.describe_collection("example-collection")
```

Delete a collection
```ruby
pinecone.delete_collection("example-collection")
```

## Contributing

Contributions welcome!

- Clone the repo locally
- `bundle` to install gems
- run tests with `rspec`
- run linter with `standardrb`
- `mv .env.copy .env` and add Pinecone API Key if developing a new endpoint or modifying existing ones
  - to disable VCR and hit real endpoints, `NO_VCR=true rspec`
- To setup cloud indexes when writing new tests `ruby spec/support/setup.rb start` and `stop` to delete them

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
