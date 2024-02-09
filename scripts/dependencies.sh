#!/bin/bash

## Downloads all external dependencies


#### Node.js deps (for graph visualization)

repo=$(git rev-parse --show-toplevel)
pushd $repo/BuildAnalyzer/Resources
npm install
popd
