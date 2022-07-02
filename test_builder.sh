#!/bin/bash

curl -X PUT localhost:8081/api/v1/build/build_bundle -H "Content-Type: application/json" \
    -H "Authorization: Bearer eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhdmFsYW5jaGUtbm9kZSIsImlzcyI6IlNlcnBlbnRPUy9Ob2RlL2xvY2FsaG9zdCIsImlhdCI6MTUxNjIzOTAyMiwiZXhwIjoxNTE2MjM5MDIyfQ.t7r3u3W0vwUVBiu50tfHnul4xmCyI3iN6b2AXQwx2M7oQGwapcAsmvvb_YZFRtHQsWiZRS5FFJAgHJhgEbeBvw" \
    -d '{"bundle": {"originType": "git", "remoteIdentifier": 123, "originURI": "git@gitlab.com:serpent-os/recipes/recipes.git", "recipePath":"nano/stone.yml", "architecture":"x86_64", "originRef":"bc3c16d61607b31dac3b0c21b93beefd213e9cf1EmA"}}'
