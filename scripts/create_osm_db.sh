home_dir=`echo ~`
this_dir=`pwd`
B
includes_dir=$this_dir/../includes

dbname=$3
dbfile=delaware-latest.osm.pbf
dbfileUrl=http://download.geofabrik.de/north-america/us/$dbfile
user=$1
pass=$2

if [[ $user == "" ]]; then
  echo    "╔════════════════════════════════════════════════════════════════════════════╗"
  echo    "  USERNAME"
  read -p "  What do you want your database user name to be?: " user
  if [[ $user == "" ]]; then
    user=osm
  fi
fi

if [[ $pass == "" ]]; then
  echo    "╔════════════════════════════════════════════════════════════════════════════╗"
  echo    "  PASSWORD"
  read -p "  What do you want your data password to be?: (default: delaware-latest.osm.pbf): " pass
  if [[ $pass == "" ]]; then
    pass=osm
  fi
fi

if [[ $dbname == "" ]]; then
  echo    "╔════════════════════════════════════════════════════════════════════════════╗"
  read -p "  What do you want to name your new database?: (default: osm): " dbname
  if [[ $dbname == "" ]]; then
    dbname=osm
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

# Postgres stuff
# Set up the OSM user and the DB
sudo -u postgres psql -c "CREATE USER $user WITH PASSWORD '$pass'"
sudo -u postgres psql -c "ALTER USER osm WITH SUPERUSER;"
sudo -u postgres dropdb $dbname
sudo -u postgres createdb -E UTF8 $dbname
sudo -u postgres createlang -d $dbname plpgsql

# Run the structure file
sudo -u postgres psql -d $dbname -f $includes_dir/db/sql/structure.sql

# Download the extract
mkdir -p $includes_dir/data
cd $includes_dir/data
if [ -a $dbfile ]; then
  rm $dbfile
fi
wget $dbfileUrl

# Load the file into the database
$includes_dir/osmosis/bin/osmosis --read-pbf file="$includes_dir/data/$dbfile" --write-apidb  database="$dbname" user="$user" password="$pass" validateSchemaVersion=no

# Update the sequences and functions
cd $this_dir/sql_scripts/
bash ./compileSql.bat
sudo -u postgres psql -d $dbname -f ./compiled.sql
sudo -u postgres psql -d $dbname -f ./compiled.sql
sudo -u postgres psql -d $dbname -f ./compiled.sql
rm ./compiled.sql

# Since we used sudo to do a lot of stuff
sudo chown -R `whoami` $includes_dir
cd $this_dir
exit
