# Pinecone Ruby Client

This is most of the Pinecone API functionality and fully tested. Please see #TODO section for the endpoints that aren't fully fleshed out yet. Contributions are welcome!

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

index.upsert(
  vectors: [{
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
```ruby
  pinecone = Pinecone::Client.new
  index = pinecone.index("example-index")
  index.delete(
    ids: ["1"], 
    namespace: "example-namespace", 
    delete_all: false
  )
```

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
  pinecone = Pinecone::Client.new
  pinecone.list_collections
```

Describe a collection
```ruby
  pinecone = Pinecone::Client.new
  pinecone.describe_collection("example-collection")
```

Delete a collection
```ruby
  pinecone = Pinecone::Client.new
  pinecone.delete_collection("example-collection")
```

## TODO

- Add filter, sparse vector and id options to query request
- Add functionality for
  - POST Describe Index Stats
  - POST Update Vectors
  - Patch configure_index

## Contributing

Contributions welcome!

- Clone the repo locally
- `bundle` to install gems
- run tests with `rspec`
- `mv .env.copy .env` and add Pinecone API Key if developing a new endpoint or modifying existing ones
  - to disable VCR and hit real endpoints, `NO_VCR=true rspec`
