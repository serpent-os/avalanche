#!/bin/bash

curl -X POST localhost:8082/api/v1/build_package -H "Content-Type: application/json" \
    -d '{"request": {"buildID": 0, "uri": "https://github.com/snekpit/main", "commitRef" : "262dc2c4c6edd4620e6eb03ad7d3aedba6e80df7", "relativePath" : "base/zlib/stone.yml", "collections": [{"indexURI": "https://dev.serpentos.com/protosnek/x86_64/stone.index", "name": "protosnek", "priority" : 0}], "buildArchitecture": "x86_64"}}'
