## 1.1.0 (2024-08-09)

- Added `GET /vectors/list` as `#list_paginated`. Thanks @xzdshr
- Added `#list` to reflect python lib and make it easy to get all vectors in an index or namespace
- Upgrade tests and cassettes
- Testing for Ruby 3.2 and 3.3. Thanks @RSO

## 1.0.0 (2024-01-29)

- Updated to Pinecone V2 API. See https://docs.pinecone.io/docs/new-api
- Breaking change to `client#list_indexes` which returns a hash instead of array now