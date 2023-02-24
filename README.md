# Pinecone Vector DB Client (WIP)

Note: This is currently minimal functionality of the Pinecone API. Pull requests to fill out the gem are welcome. I recommend reading the code directly if you're going to use it.

## Installation

`gem install pinecone`

## Configuration

```ruby
require 'pinecone'

Pinecone.configure do |config|
  config.api_key  = ENV.fetch('PINECONE_API_KEY')
  config.base_uri = ENV.fetch('PINECONE_BASE_URI') # https://index_name-project_id.svc.environment.pinecone.io
end
```

## Features

Adding vectors to an existing DB
```ruby
pinecone = Pinecone::Client.new
# Note, options are currently hardcoded in this method
# Index is set within base_uri
pinecone.upsert(
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

Querying DB with a vector
```ruby
  embedding = [0.0, -0.2, 0.4]
  pinecone = Pinecone::Client.new
  response = pinecode.query(embedding)
  response #=> 
```

## TODO

- Robust funcitonality (errors, options etc) for
  - Upsert
  - Query
- Add functionality for
  - GET Describe Index Stats
  - POST Describe Index Stats
  - DELETE Delete Vectors
  - POST Delete Vectors
  - GET Fetch
  - POST Update
  - GET list_collections
  - POST create_collection
  - GET describe_collection
  - DELETE delete_collection
  - GET list_indexes
  - POST create_index
  - GET describe_index
  - DELETE delete_index
  - Patch configure_index
