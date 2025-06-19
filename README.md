# Pinecone Ruby Client
[![Gem Version](https://badge.fury.io/rb/pinecone.svg)](https://badge.fury.io/rb/pinecone)
![GitHub](https://img.shields.io/github/license/scotterc/pinecone)

[Ruby AI Builders Discord](https://discord.gg/k4Uc224xVD)

This is the complete Pinecone API and fully tested. Bug reports and contributions are welcome!

## What's New in v1.2

- 🚀 **Host-based index targeting** for better performance (eliminates extra API calls)
- 🐳 **Local development support** with Pinecone containers  
- ⚙️ **Flexible configuration** with global host settings

## Installation

`gem install pinecone`

## Configuration

### Basic Configuration

```ruby
require "dotenv/load"
require 'pinecone'

Pinecone.configure do |config|
  config.api_key = ENV.fetch('PINECONE_API_KEY')
  config.environment = ENV.fetch('PINECONE_ENVIRONMENT')  # Optional in v1.2+
end
```

### v1.2+ Host-Based Configuration (Recommended)

For better performance, you can configure a default index host:

```ruby
Pinecone.configure do |config|
  config.api_key = ENV.fetch('PINECONE_API_KEY')
  config.host = ENV.fetch('PINECONE_INDEX_HOST')  # e.g., "my-index-abc123.svc.us-east1.pinecone.io"
end
```

### Local Development

For local development with Pinecone containers:

```ruby
Pinecone.configure do |config|
  config.api_key = "dummy-key"  # Not required for local containers
  config.host = "localhost:5081"  # Automatically uses HTTP for localhost
  config.silence_deprecation_warnings = true  # Optional: silence warnings in tests
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

### Index Access

**v1.2+ Recommended (Host-Based):**
```ruby
pinecone = Pinecone::Client.new

# Option 1: Use global host (configured above)
index = pinecone.index()

# Option 2: Specify host directly (best performance)
index = pinecone.index(host: "my-index-abc123.svc.us-east1.pinecone.io")

# Option 3: Multiple indexes with different hosts
dense_index = pinecone.index(host: "dense-index-host.svc.pinecone.io")
sparse_index = pinecone.index(host: "sparse-index-host.svc.pinecone.io")
```

**Legacy (Still Supported):**
```ruby
pinecone = Pinecone::Client.new
index = pinecone.index("example-index")  # ⚠️ Makes extra API call
```

### Adding Vectors

```ruby
pinecone = Pinecone::Client.new
index = pinecone.index(host: "your-index-host")

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

### Querying Vectors

```ruby
pinecone = Pinecone::Client.new
index = pinecone.index(host: "your-index-host")
embedding = [0.0, -0.2, 0.4]
response = index.query(vector: embedding)
```

Querying with options:
```ruby
pinecone = Pinecone::Client.new
index = pinecone.index(host: "your-index-host")
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
index = pinecone.index(host: "your-example-index")
index.fetch(
  ids: ["1"], 
  namespace: "example-namespace"
)
```

List all vector IDs (only for serverless indexes)
```ruby
pinecone = Pinecone::Client.new
index = pinecone.index(host: "your-example-index")
index.list(
  namespace: "example-namespace",
  prefix: "example-prefix",
)


index.list(
  namespace: "example-namespace",
  prefix: "example-prefix",
  limit: 150
) do |vector_id|
  puts vector_id
end
```

List vector IDs with pagination (only for serverless indexes)
(default limit of 100)
```ruby
pinecone = Pinecone::Client.new
index = pinecone.index(host: "your-example-index")
index.list_paginated(
  namespace: "example-namespace",
  prefix: "example-prefix",
  limit: 50,
  pagination_token: "example-token"
)
```

Updating a vector in an index
```ruby
pinecone = Pinecone::Client.new
index = pinecone.index(host: "your-example-index")
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
index = pinecone.index(host: "your-example-index")
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
index = pinecone.index(host: "your-example-index")
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
index = pinecone.index(host: "your-example-index")
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
index = pinecone.index(host: "your-example-index")
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
index = pinecone.index(host: "your-example-index")
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

### Local Development with Containers

For local development and testing:
```bash
# Start local Pinecone containers
docker-compose -f docker-compose.test.yml up -d

# Run local container tests
bundle exec rspec spec/local_container_spec.rb

# Run all tests
bundle exec rspec

# Stop containers
docker-compose -f docker-compose.test.yml down
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
