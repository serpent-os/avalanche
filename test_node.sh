#!/bin/bash

curl -X PUT localhost:8081/api/v1/node/build_bundle -H "Content-Type: application/json" \
    -d '{"bundle": {"originType": "git", "remoteIdentifier": 123, "originURI": "git@gitlab.com:serpent-os/recipes/recipes.git", "recipePath":"nano/stone.yml", "architecture":"x86_64", "originRef":"bc3c16d61607b31dac3b0c21b93beefd213e9cf1EmA"}}'
