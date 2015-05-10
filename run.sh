# Public is our build directory:

ROOT=`pwd` 

# In root
mkdir -p public
rm -rf public/libs
cp -r *.zrf client/*.html client/libs client/css client/images client/jmarine public
rm -f public/bin.js

rm -rf "$ROOT/client/temp"
mkdir -p "$ROOT/client/temp"

cp -r "$ROOT/client/jmarine" "$ROOT/client/"*.coffee "$ROOT/client/"*.js "$ROOT/client/temp"

# In root/client/temp
cd "$ROOT/client/temp"
"$ROOT/node_modules/.bin/coffee" -c *.coffee jmarine/*.coffee
"$ROOT/node_modules/.bin/browserify" app.js > "$ROOT/public/bin.js"

# In root/public
cd "$ROOT/public"
google-chrome --disable-web-security index.html

rm -rf public
