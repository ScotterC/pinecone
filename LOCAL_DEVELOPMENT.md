# Local Development with Pinecone Containers

This guide explains how to use the Pinecone local containers for development and testing.

## Quick Start

1. **Start the local containers:**
   ```bash
   docker-compose -f docker-compose.test.yml up -d
   ```

   This starts three containers:
   - **Database Emulator**: `localhost:5080` (control plane operations - create/delete indexes)
   - **Dense Index**: `localhost:5081` (2D vectors, cosine similarity)
   - **Sparse Index**: `localhost:5082` (sparse vectors, dotproduct similarity)

2. **Configure your client for dense vectors:**
   ```ruby
   Pinecone.configure do |config|
     config.api_key = "dummy-key"  # Local containers don't require auth
     config.host = "localhost:5081"
   end

   client = Pinecone::Client.new
   index = client.index()  # Uses global host
   ```

3. **Or use direct host targeting:**
   ```ruby
   client = Pinecone::Client.new
   dense_index = client.index(host: "localhost:5081")
   sparse_index = client.index(host: "localhost:5082")
   ```

## Features

### Host-Based Index Targeting

The v1.2+ API supports direct host targeting for better performance:

```ruby
# Direct host (recommended for production)
index = client.index(host: "my-index-abc123.svc.us-east1.pinecone.io")

# Global host configuration
Pinecone.configure do |config|
  config.api_key = ENV['PINECONE_API_KEY']
  config.host = ENV['PINECONE_INDEX_HOST']
end
index = client.index()  # Uses global host

# Legacy approach (deprecated but still works)
index = client.index("index-name")  # Makes extra API call
```

### Benefits of Host-Based Approach

1. **No extra API calls** - Eliminates `describe_index` call on every initialization
2. **Better performance** - Direct connection to index host
3. **Production ready** - Follows Pinecone's recommended patterns
4. **Perfect for local development** - Works seamlessly with local container

## Testing

### Unit Tests (No Container Required)
```bash
bundle exec rspec spec/pinecone/client_spec.rb -e "host parameter"
```

### Local Container Tests
```bash
# Start container
docker-compose -f docker-compose.test.yml up -d

# Run local container tests
bundle exec rspec spec/local_container_spec.rb

# Stop container
docker-compose -f docker-compose.test.yml down
```

### All Tests (Including VCR)
```bash
bundle exec rspec
```

## Configuration Options

### Silence Deprecation Warnings

Useful for tests or production environments:

```ruby
Pinecone.configure do |config|
  config.api_key = "your-key"
  config.silence_deprecation_warnings = true
end
```

## Container Specifications

### Database Emulator (Port 5080)
- **Purpose**: Control plane operations (create/delete indexes, list indexes)
- **Endpoints**: `/indexes`, `/indexes/{name}`
- **Usage**: For testing index management operations

Example usage:
```ruby
# Note: This requires special configuration to point Index operations to the database emulator
client = database_client  # Special helper method
response = client.list_indexes
```

### Dense Index Container (Port 5081)
- **Dimension**: 2
- **Metric**: cosine
- **Vector Type**: dense
- **Index Type**: serverless

Example usage:
```ruby
client = Pinecone::Client.new
index = client.index(host: "localhost:5081")

# Upsert 2D dense vectors
vectors = {
  vectors: [
    { id: "vec1", values: [0.1, 0.2] },
    { id: "vec2", values: [0.3, 0.4] }
  ]
}
index.upsert(vectors)

# Query with 2D vector
query = {
  vector: [0.1, 0.2],
  topK: 5,
  includeValues: true
}
index.query(query)
```

### Sparse Index Container (Port 5082)
- **Dimension**: 0 (dynamic)
- **Metric**: dotproduct
- **Vector Type**: sparse
- **Index Type**: serverless

Example usage:
```ruby
client = Pinecone::Client.new
index = client.index(host: "localhost:5082")

# Upsert sparse vectors
vectors = {
  vectors: [
    { 
      id: "sparse1", 
      sparseValues: { indices: [0, 100, 200], values: [0.1, 0.2, 0.3] }
    }
  ]
}
index.upsert(vectors)

# Query with sparse vector
query = {
  sparseVector: { indices: [0, 100], values: [0.1, 0.2] },
  topK: 5,
  includeValues: true
}
index.query(query)
```

### Environment Variables

For local development, set these in your `.env` file:

```bash
# For cloud testing (optional)
PINECONE_API_KEY=your-cloud-api-key
PINECONE_ENVIRONMENT=your-environment

# For host-based approach
PINECONE_DENSE_HOST=localhost:5081    # or your production dense index host
PINECONE_SPARSE_HOST=localhost:5082   # or your production sparse index host
```

## Migration Guide

### From v1.1 to v1.2

**Before:**
```ruby
Pinecone.configure do |config|
  config.api_key = ENV['PINECONE_API_KEY']
  config.environment = ENV['PINECONE_ENVIRONMENT']
end

client = Pinecone::Client.new
index = client.index("my-index")  # Makes describe_index API call
```

**After (Option 1 - Global Host):**
```ruby
Pinecone.configure do |config|
  config.api_key = ENV['PINECONE_API_KEY']
  config.host = ENV['PINECONE_INDEX_HOST']
end

client = Pinecone::Client.new
index = client.index()  # No API call
```

**After (Option 2 - Per-Index Host):**
```ruby
Pinecone.configure do |config|
  config.api_key = ENV['PINECONE_API_KEY']
end

client = Pinecone::Client.new
index = client.index(host: ENV['PINECONE_INDEX_HOST'])  # No API call
```

### Getting Your Index Host

You can find your index host in:

1. **Pinecone Console:** Copy from the "Connect" tab
2. **One-time API call:**
   ```ruby
   client = Pinecone::Client.new
   response = client.describe_index("my-index")
   host = response.parsed_response["host"]
   puts "Set PINECONE_INDEX_HOST=#{host}"
   ```

## Troubleshooting

### Containers Not Starting

Check if ports are available:
```bash
lsof -i :5080  # Database emulator
lsof -i :5081  # Dense index
lsof -i :5082  # Sparse index
```

### Connection Issues

Verify containers are running:
```bash
curl -I http://localhost:5080/indexes    # Database emulator
curl -I http://localhost:5081/vectors/list  # Dense index
curl -I http://localhost:5082/vectors/list  # Sparse index
```

All should return `HTTP/1.1 200 OK`.

### Test Failures

Make sure to clean up between tests:
```ruby
# In your tests
after(:each) do
  index.delete(delete_all: true)
end
```

## Docker Compose Configuration

The `docker-compose.test.yml` includes:

- **Pinecone Local Container**: Latest official image
- **Port Mapping**: 8080:8080
- **Health Checks**: Ensures container is ready
- **Environment Variables**: Configures API version

To customize the container, edit the environment variables in `docker-compose.test.yml`.