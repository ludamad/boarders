#!/bin/bash

source scripts/util.sh # does set +e; provides 'has_flag' and 'resolved_args'

# Allow for using binaries in node_modules/:
export PATH="`pwd`/node_modules/.bin/:$PATH"

if has_flag "--help" || [ "$1" = "" ] ; then
    echo "Usage: Use one or more of the following 
  --client-hosted:
    Open web page from server over localhost.
  --client:
    Open locally built web page in browser.
  --server:
    Start server on localhost.
  --native_client:
    Run native test client."
    exit
fi

######################################################
# RUN SECTION
######################################################

if has_flag "--server" ; then
    node build/server/loader.js
elif has_flag "--client" ; then
    #electron build/client/ui-test-loader.js index
    electron build/client/ui-test-loader.js board
elif has_flag "--client-hosted" ; then
    google-chrome --disable-web-security http://localhost:8081/index.html
elif has_flag "--test" ; then
    pushd build/test
    mocha
    popd
else
    electron build/client/ui-test-loader.js $1
fi
