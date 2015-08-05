#!/bin/bash

source scripts/util.sh # does set +e; provides 'has_flag' and 'resolved_args'

# Allow for using binaries in node_modules/:
export PATH="`pwd`/node_modules/.bin/:$PATH"

if has_flag "--help" ; then
    echo "
  ** Usage: Use one or more of the following **
  --setup: 
    Setup for building. Clone submodules, run 'node install' in subfolders.
  --client:
    Compile HTML client.
    Open locally built web page in browser.
  --server:
    Start server on localhost.
  --native_client:
    Compile native client.
    Run headless test client.
"
    exit
fi

######################################################
# SETUP SECTION
######################################################

# Run 'npm install'; clone submodules:
if has_flag "--setup" ; then
    # Run 'npm install' 
    npm install

    # Clone submodules, in 'scripts/' (a bit of a hijack of purpose, but all well)
    pushd src
    if [ ! -d DefinitelyTyped ] ; then
        # In theory we would want to check out a specific commit,
        # but while development is still experimental I see nothing
        # wrong for now.
        git clone --depth=1 https://github.com/borisyankov/DefinitelyTyped/

        # HERE BE HACK
        # Since we in general strive to use very up-to-date JavaScript tech,
        # lets patch an issue with using TypeScript HEAD with ES6 export enabled.
        for file in DefinitelyTyped/*/*.ts ; do
            sed -i "s@import *\(.*\)= *require(\([\"'].*[\"']))@import * as \1from \2@g"  "$file"; 
        done
    fi
    popd
fi

if [ ! -d node_modules ] ; then
    echo "Node.js dependencies have not been installed; please use './build.sh --setup'."
    exit
fi
if [ ! -d src/DefinitelyTyped ] ; then
    echo "DefinitelyTyped has not been cloned; please use './build.sh --setup'."
    exit
fi

######################################################
# BUILD SECTION
######################################################

if has_flag "--server" ; then
    node ./scripts/tsc-bundled/tsc.js -project src/server &&\
    pushd ./build/server-es6/ &&\
    babel --optional runtime -d ../server/ *.js &&\
    popd 
    #"$SCRIPT_NODE_BIN/browserify" "$SERVER_DIR/main.ts" -p tsify -t babelify --outfile "$BUILD_DIR/server/main.js"
fi

if has_flag "--client" ; then
    pushd "$ROOT_DIR/client"
    mkdir -p "$BUILD_DIR/client"
    popd
#  "scripts": {
#    "build-server": "./setup.sh --server",
#    "build-client": "coffee -o ./build/client-es6/ -c ./client/*.coffee && browserify [ babel --optional runtime ] --outfile ./build/client/bin.js ./build/client-es6/*.js"
#  }
fi

if has_flag "--native_client" ; then
    pushd "$ROOT_DIR/native_client"
    popd
fi
