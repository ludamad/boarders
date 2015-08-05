#!/bin/bash

source scripts/util.sh # does set +e; provides 'has_flag' and 'resolved_args'

# Allow for using binaries in node_modules/:
export PATH="`pwd`/node_modules/.bin/:$PATH"

if has_flag "--help" || [ "$1" = "" ] ; then
    echo "Usage: Use one or more of the following
  --setup: 
    Setup for building. Clone submodules, run 'npm install'.
  --client:
    Compile HTML client.
    Open locally built web page in browser.
  --server:
    Start server on localhost.
  --native_client:
    Compile native client.
    Run headless test client."
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
    echo "Running TypeScript"
    # Compile over typescript files to build/server-es6
    node ./scripts/tsc-bundled/tsc.js -project src/server 
    pushd ./build/server-es6/ 
    babel --optional runtime -d ../server/ *.js
    popd 
    #"$SCRIPT_NODE_BIN/browserify" "$SERVER_DIR/main.ts" -p tsify -t babelify --outfile "$BUILD_DIR/server/main.js"
fi

if has_flag "--client" ; then
    rm -rf build/client && mkdir -p build/client
    # Copy over non-coffee files
    cp -r src/client/*.html src/client/libs src/client/models src/client/css src/client/images src/client/jmarine/*.js build/client
    rm -f build/client/bin.js # Prevent mistakes if build fails

    # Compile over coffee files
#    pushd src
#    coffee -o build/client -c models/*.coffee
#    popd

    # Compile over typescript files to build/client-es6
    node ./scripts/tsc-bundled/tsc.js -project src/client

    # Run browserify:
    browserify build/client-es6/loader.js -t [ babelify --optional runtime --loose all ] --outfile build/client/bin.js
fi

