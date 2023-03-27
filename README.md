# Pinecone Ruby Client

Note: This is currently minimal functionality of the Pinecone API. Pull requests to fill out the gem are welcome.

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
})
```

Delete Index
```ruby
pinecone.delete_index("example-index")
```

## Vector Operations

Adding vectors to an existing index
```ruby
pinecone = Pinecone::Client.new
index = pinecone.index("example-index")

# Note, options are currently hardcoded in this method
index.upsert(
  vectors: {
    id: "1",
    metadata: {
      key: value
    },
    namespace: "example-namespace",
    values: [
      0.1,
      0.2,
      0.0
    ]
  }
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

Deleting a vector from an index
```ruby
  pinecone = Pinecone::Client.new
  index = pinecone.index("example-index")
  index.delete(
    ids: ["1"], 
    namespace: "example-namespace", 
    delete_all: false
  )
```

## Supported Endpoints

Vector 

- Upsert
- Query
- Fetch
- Delete

Index

- List Indexes
- Describe Index
- Create Index
- Delete Index

## TODO

- Add filter, sparse vector and id options to query request
- Add functionality for
  - POST Describe Index Stats
  - POST Update Vectors
  - GET list_collections
  - POST create_collection
  - GET describe_collection
  - DELETE delete_collection
  - Patch configure_index
