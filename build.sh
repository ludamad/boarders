#!/bin/bash

source scripts/util.sh # does set +e; provides 'has_flag' and 'resolved_args'

# Allow for using binaries in node_modules/:
export PATH="`pwd`/node_modules/.bin/:$PATH"

if has_flag "--help" ; then
    echo "Usage: Use one or more of the following
  --client:
    Build HTML client."
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

rm -rf ./build/ && mkdir -p ./build
echo "Running TypeScript compiler on src/... (fills ./build/es6)"
node ./scripts/tsc-bundled/tsc.js -project src
echo "Running Babel compiler on ./build/es6 (fills ./build/)"
pushd ./build/es6 && babel --optional runtime --loose all -d ../ `find -name '*.js'` && popd

# Copy over non-coffee files
cp -r src/client/*.html src/client/libs src/client/models src/client/css src/client/images src/client/jmarine/*.js build/client
cp -r src/native/*.html build/client
cp -r build/native/*.js build/client
rm -f build/client/bin.js # Prevent mistakes if build fails

    # Compile over coffee files
#    pushd src
#    coffee -o build/client -c models/*.coffee
#    popd

# TODO revisit flag business
if has_flag "--client" ; then
    # Run browserify:
    browserify build/client/loader.js --outfile build/client/bin.js
fi

