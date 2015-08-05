#!/bin/bash

source scripts/util.sh # does set +e; provides 'has_flag' and 'resolved_args'

if has_flag "--help" ; then
    echo "
  ** Usage: Use one or more of the following **
  --client-hosted:
    Open web page from server over localhost.
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

if has_flag "--client" ; then
    google-chrome --disable-web-security build/client/index.html
fi

if has_flag "--client-hosted" ; then
    google-chrome --disable-web-security http://localhost:8081/index.html
fi

