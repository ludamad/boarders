# Public is our build directory:

ROOT=`pwd` 

# In root
mkdir -p build
rm -rf build/libs
cp -r *.zrf client/*.html client/libs client/css client/images client/jmarine build
rm -f build/bin.js

rm -rf "$ROOT/build/src"
mkdir -p "$ROOT/build/src"

cp -r "$ROOT/client/jmarine" "$ROOT/client/"*.coffee "$ROOT/client/"*.js "$ROOT/build/src"

# In root/build/src
cd "$ROOT/build/src"
"$ROOT/node_modules/.bin/coffee" -c *.coffee jmarine/*.coffee
"$ROOT/node_modules/.bin/browserify" app.js > "$ROOT/build/bin.js"

# In root/build
cd "$ROOT/build"
google-chrome --disable-web-security index.html

rm -rf build
