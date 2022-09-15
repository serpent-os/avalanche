#!/bin/bash

curl -X POST localhost:8082/api/v1/build_package -H "Content-Type: application/json" \
    -d '{"request": {"buildID": 0, "uri": "https://github.com/snekpit/main", "commitRef" : "8ba4eaec63e8bbb7e5c9c22712f9a696bb5d85e4", "relativePath" : "base/zlib/stone.yml", "collections": [{"indexURI": "https://dev.serpentos.com/protosnek/x86_64/stone.index", "name": "protosnek", "priority" : 0}], "buildArchitecture": "x86_64"}}'
