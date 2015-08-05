#!/bin/bash

SRC_DIR=$(dirname "${BASH_SOURCE[0]}") 
SERVER_DIR="$SRC_DIR/../server/"

if [ "$1" = i ]; then
    cd "$SERVER_DIR" && npm install
else
    cd "$SERVER_DIR" && node index.js
fi
