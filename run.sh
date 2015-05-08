# Public is our build directory:
mkdir -p public
rm -rf public/libs
cp -r *.zrf client/*.css client/*.html client/libs client/css client/images public
rm -f public/bin.js

cd client
for file in *.js ; do
    ../node_modules/.bin/browserify $file >> ../public/bin.js
done
for file in *.coffee ; do
    ../node_modules/.bin/browserify -t coffeeify --extension=".coffee" $file >> ../public/bin.js
done
cd ..
#node index.js &

cd public
google-chrome --disable-web-security index.html
