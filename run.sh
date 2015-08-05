#!/bin/bash

source scripts/util.sh # does set +e; provides 'has_flag' and 'resolved_args'

if has_flag "--help" ; then
    echo "
  ** Usage: Use one or more of the following **
  --client:
    Open locally built web page in browser.
  --server:
    Start server on localhost.
  --native_client:
    Run native test client.
"
    exit
fi

######################################################
# RUN SECTION
######################################################

if has_flag "--server" ; then
    node build/server/loader.js
fi


