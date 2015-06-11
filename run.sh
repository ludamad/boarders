# Public is our build directory:

ROOT=`pwd` 

if [ ! -e "$ROOT/server/node_modules" ] ; then
    echo "Run npm install in server/, please."
fi

# In root
mkdir -p build
rm -rf build/libs
cp -r client/*.html client/libs client/models client/css client/images client/jmarine build
rm -f build/bin.js

rm -rf "$ROOT/build/src"
mkdir -p "$ROOT/build/src"

cp -r "$ROOT/client/jmarine" "$ROOT/client/models/" "$ROOT/client/"*.coffee "$ROOT/client/"*.js "$ROOT/build/src"

# In root/build/src
cd "$ROOT/build/src"
"$ROOT/server/node_modules/.bin/coffee" -c *.coffee jmarine/*.coffee models/*.coffee
"$ROOT/server/node_modules/.bin/browserify" app.js > "$ROOT/build/bin.js"

# In root/build
cd "$ROOT/build"
google-chrome --disable-web-security index.html

rm -rf build
