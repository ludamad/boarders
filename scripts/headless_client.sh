#!/bin/bash

SRC_DIR=$(dirname "${BASH_SOURCE[0]}") 
HEADLESS_DIR="$SRC_DIR/../headless_client/"

if [ "$1" = i ]; then
    cd "$HEADLESS_DIR" && npm install
else
    cd "$HEADLESS_DIR" && node index.js
fi
