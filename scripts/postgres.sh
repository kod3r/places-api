#!/bin/bash
echo "╔══════════════════════════════════╗"
echo "     Installing postgresql 9.3"
echo "╚══════════════════════════════════╝"

wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" >> /etc/apt/sources.list.d/postgresql.list'
apt-get -y update
apt-get -y install postgresql-9.3 postgresql-contrib-9.3 libpq-dev postgresql-server-dev-all postgresql-client-common

# Set up user information
echo "╔══════════════════════════════════╗"
echo "  Set your postgres UNIX password"
echo "╚══════════════════════════════════╝"

sudo passwd postgres
echo    "╔════════════════════════════════════════════════════════════════════════════╗"
read -p "  What do you want to postgres database password to be?: (default: postgres): " postgres_pw

if [[ $postgres_pw == "" ]]; then
  postgres_pw=postgres
fi

sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$postgres_pw';"


# Change settings in the hba.conf and postgresql.conf files
echo "╔════════════════════════════════════════════════════════════════════════════════════════════════╗"
echo "  Do you want to set up postgres to accept all outside connections (this is ok for a walled VM)?"
select yn in "Yes" "No"; do
    case $yn in
        Yes )
                sudo sed -i 's/127\.0\.0\.1\/32/0.0.0.0\/0/g' `sudo -u postgres psql -c 'show hba_file' | grep hba.conf`
                sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" `sudo -u postgres psql -c 'show config_file' | grep postgresql.conf`
                sudo /etc/init.d/postgresql stop
                sudo /etc/init.d/postgresql start
                break;;
        No ) break;;
    esac
done

echo -e "\033[34m"
echo "╔═════════════════════════════════════════════════════════════════╗"
echo "║  Install Osmosis                                                ║"
echo "╟─────────────────────────────────────────────────────────────────╢"
echo "║  Some of this information can be found here:                    ║"
echo "║     http://wiki.openstreetmap.org/wiki/Osmosis#Latest_Stable_Version"
echo "╚═════════════════════════════════════════════════════════════════╝"
echo -e "\033[0m"
echo ""
home_dir=`echo ~`
cur_dir=`pwd`
mkdir -p $home_dir/installation/osmosis
cd $home_dir/installation/osmosis

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

mkdir -p $home_dir/installation/db/functions/quad_tile
mkdir -p $home_dir/installation/db/sql
cd $home_dir/installation/db/sql
wget https://raw.github.com/openstreetmap/openstreetmap-website/master/db/structure.sql
cd $home_dir/installation/db/functions
wget https://github.com/openstreetmap/openstreetmap-website/raw/master/db/functions/maptile.c
wget https://github.com/openstreetmap/openstreetmap-website/raw/master/db/functions/quadtile.c
wget https://github.com/openstreetmap/openstreetmap-website/raw/master/db/functions/xid_to_int4.c
wget https://raw.github.com/openstreetmap/openstreetmap-website/master/db/functions/Makefile
cd $home_dir/installation/db/functions/quad_tile
wget https://raw.github.com/openstreetmap/openstreetmap-website/master/lib/quad_tile/extconf.rb
wget https://raw.github.com/openstreetmap/openstreetmap-website/master/lib/quad_tile/quad_tile.c
wget https://raw.github.com/openstreetmap/openstreetmap-website/master/lib/quad_tile/quad_tile.h

# Clean up the makefile
sed -i 's/\.\.\/\.\.\/lib\/quad_tile/quad_tile/g' $home_dir/installation/db/functions/Makefile

# Clean up the install scripts
sed -i 's:/srv/www/master.osm.compton.nu/db/functions/:'$home_dir'/installation/db/functions/:g' $home_dir/installation/db/sql/structure.sql

cd $home_dir/installation/db/functions/
make

cd $cur_dir
echo -e "\033[32m"
echo "╔════════════════════════════════════════>"
echo "  Osmosis is now installed on "`hostname`
echo "╚════════════════════════════════════════>"
echo -e "\033[0m"
exit
