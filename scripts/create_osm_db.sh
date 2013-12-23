home_dir=`echo ~`
this_dir=`pwd`
includes_dir=$this_dir/../includes

dbnameapi=$3
dbnamepgs=$4
dbfile=delaware-latest.osm.pbf
dbfileUrl=http://download.geofabrik.de/north-america/us/$dbfile
user=$1
pass=$2

if [[ $user == "" ]]; then
  echo    "╔════════════════════════════════════════════════════════════════════════════╗"
  echo    "  USERNAME"
  read -p "  What do you want your database user name to be? (default: osm): " user
  if [[ $user == "" ]]; then
    user=osm
  fi
fi

if [[ $pass == "" ]]; then
  echo    "╔════════════════════════════════════════════════════════════════════════════╗"
  echo    "  PASSWORD"
  read -p "  What do you want your database password to be? (default: osm): " pass
  if [[ $pass == "" ]]; then
    pass=osm
  fi
fi

if [[ $dbnameapi == "" ]]; then
  echo    "╔════════════════════════════════════════════════════════════════════════════╗"
  echo    " DATABASE NAME API"
  read -p "  What do you want to name your new API database? (default: osm_api): " dbnameapi
  if [[ $dbnameapi == "" ]]; then
    dbnameapi=osm_api
  fi
fi

if [[ $dbnamepgs == "" ]]; then
  echo    "╔════════════════════════════════════════════════════════════════════════════╗"
  echo    " DATABASE NAME Rendering (pgsnapshot)"
  read -p "  What do you want to name your new rendering database? (default: osm_pgs): " dbnamepgs
  if [[ $dbnamepgs == "" ]]; then
    $dbnamepgs=osm_pgs
  fi
fi

echo    "╔════════════════════════════════════════════════════════════════════════════╗"
read -p "  What file do you want to download from geofabrik?: (default: delaware-latest.osm.pbf): " dbfile
if [[ $dbfile == "" ]]; then
  dbfile=delaware-latest.osm.pbf
fi

echo -e "\033[34m"
echo "╔═════════════════════════════════════════════════════════════════╗"
echo "║  Install Osmosis                                                ║"
echo "╟─────────────────────────────────────────────────────────────────╢"
echo "║  Some of this information can be found here:                    ║"
echo "║     http://wiki.openstreetmap.org/wiki/Osmosis#Latest_Stable_Version"
echo "╚═════════════════════════════════════════════════════════════════╝"
echo -e "\033[0m"
echo ""
mkdir -p $includes_dir/osmosis
cd $includes_dir/osmosis

echo -e "\033[33m──━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━──\033[0m"
echo            "  Installing Java and unzip tools"
echo -e "\033[33m──━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━──\033[0m"
sudo apt-get -y install unzip openjdk-6-jdk

echo -e "\033[33m──━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━──\033[0m"
echo            "  Downloading and extracting Osmosis"
echo -e "\033[33m──━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━──\033[0m"
if [ -a "osmosis-latest.zip" ]; then
  rm osmosis-latest.zip
fi
wget http://bretth.dev.openstreetmap.org/osmosis-build/osmosis-latest.zip
unzip osmosis-latest.zip
sudo ln -s ./bin/osmosis /usr/bin/osmosis
echo -e "\033[33m──━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━──\033[0m"
echo            "  Downloading and Osmosis schemas for APIDB and pgsql functions"
echo            "  More Information Here:"
echo            "   http://wiki.openstreetmap.org/wiki/Database_schema#Database_Schema"
echo -e "\033[33m──━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━──\033[0m"

if [ -d $includes_dir/db/ ]; then
  sudo rm -rf $includes_dir/db/
fi
mkdir -p $includes_dir/db/functions/quad_tile
mkdir -p $includes_dir/db/sql
cd $includes_dir/db/sql
wget https://raw.github.com/openstreetmap/openstreetmap-website/master/db/structure.sql
wget https://raw.github.com/openstreetmap/osmosis/master/package/script/pgsnapshot_schema_0.6.sql

cd $includes_dir/db/functions
wget https://github.com/openstreetmap/openstreetmap-website/raw/master/db/functions/maptile.c
wget https://github.com/openstreetmap/openstreetmap-website/raw/master/db/functions/quadtile.c
wget https://github.com/openstreetmap/openstreetmap-website/raw/master/db/functions/xid_to_int4.c
wget https://raw.github.com/openstreetmap/openstreetmap-website/master/db/functions/Makefile

cd $includes_dir/db/functions/quad_tile
wget https://raw.github.com/openstreetmap/openstreetmap-website/master/lib/quad_tile/extconf.rb
wget https://raw.github.com/openstreetmap/openstreetmap-website/master/lib/quad_tile/quad_tile.c
wget https://raw.github.com/openstreetmap/openstreetmap-website/master/lib/quad_tile/quad_tile.h

# Clean up the makefile
sed -i 's/\.\.\/\.\.\/lib\/quad_tile/quad_tile/g' $includes_dir/db/functions/Makefile
cd $includes_dir/db/functions
make

# Postgres stuff
# Set up the OSM user and the DB
sudo -u postgres psql -c "CREATE USER $user WITH PASSWORD '$pass'"
sudo -u postgres psql -c "ALTER USER osm WITH SUPERUSER;"
sudo -u postgres dropdb $dbnameapi
sudo -u postgres createdb -E UTF8 $dbnameapi
sudo -u postgres createlang -d $dbnameapi plpgsql
sudo -u postgres dropdb $dbnamepgs
sudo -u postgres createdb -E UTF8 $dbnamepgs
sudo -u postgres createlang -d $dbnamepgs plpgsql

# Run the structure file
sudo sed -i "s:/srv/www/master.osm.compton.nu:$includes_dir:g" $includes_dir/db/sql/structure.sql
sudo -u postgres psql -d $dbnameapi -f $includes_dir/db/sql/structure.sql
sudo -u postgres psql -d $dbnameapi -c "CREATE EXTENSION dblink;"

sudo -u postgres psql -d $dbnamepgs -c "CREATE EXTENSION postgis;"
sudo -u postgres psql -d $dbnamepgs -c "CREATE EXTENSION postgis_topology;"
sudo -u postgres psql -d $dbnamepgs -c "CREATE EXTENSION hstore;"
sudo -u postgres psql -d $dbnamepgs -f $includes_dir/db/sql/pgsnapshot_schema_0.6.sql

# Download the extract
mkdir -p $includes_dir/data
cd $includes_dir/data
if [ -a $dbfile ]; then
  rm $dbfile
fi
wget $dbfileUrl

# Load the file into the database
$includes_dir/osmosis/bin/osmosis --read-pbf file="$includes_dir/data/$dbfile" --write-apidb  database="$dbnameapi" user="$user" password="$pass" validateSchemaVersion=no
$includes_dir/osmosis/bin/osmosis --read-pbf file="$includes_dir/data/$dbfile" --write-pgsql  database="$dbnamepgs" user="$user" password="$pass"

# Update the sequences and functions
cd $this_dir/sql_scripts/
bash ./compileSql.bat
sudo -u postgres psql -d $dbnameapi -f ./compiled.sql
sudo -u postgres psql -d $dbnameapi -f ./compiled.sql
sudo -u postgres psql -d $dbnameapi -f ./compiled.sql
rm ./compiled.sql

# Since we used sudo to do a lot of stuff, make it easy for the current user
sudo chown -R `whoami` $includes_dir
cd $this_dir
exit
