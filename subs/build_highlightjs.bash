#!/bin/bash

set -e

pushd "$( dirname "${BASH_SOURCE}" )" >/dev/null 2>&1
pushd  highlightjs >/dev/null 2>&1

npm install
find node_modules -type d -name .git -prune -exec rm -rf {} \;
npm audit fix
node tools/build.js

popd >/dev/null 2>&1
popd >/dev/null 2>&1