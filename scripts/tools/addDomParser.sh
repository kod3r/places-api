osm_geojson_dir=$1

curr_dir=`pwd`
cd $osm_geojson_dir
npm install xmldom
sed -i "1ivar DOMParser = require('xmldom').DOMParser;" osm_geojson.js

cd $curr_dir
