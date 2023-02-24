# Pinecone Vector DB Client (WIP)

Note: This is currently minimal functionality of the Pinecone API. Pull requests to fill out the gem are welcome.

## Installation

`gem install pinecone`

## Configuration

```ruby
require "dotenv/load"
require 'pinecone'

Pinecone.configure do |config|
  config.api_key  = ENV.fetch('PINECONE_API_KEY')
  config.environemnt = ENV.fetch('PINECONE_ENVIRONMENT')
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
  response = index.query(embedding)
```

## Supported Endpoints

Vector 

- Upsert
- Query

Index

- List Indexes
- Describe Index
- Create Index
- Delete Index

## TODO

- Resolve the index_name_project_id issue
- Add functionality for
  - POST Describe Index Stats
  - POST Delete Vectors
  - GET Fetch
  - POST Update
  - GET list_collections
  - POST create_collection
  - GET describe_collection
  - DELETE delete_collection
  - Patch configure_index
