#!/bin/bash
echo "╔══════════════════════════════════╗"
echo "     Installing postgresql 9.1"
echo "╚══════════════════════════════════╝"

apt-get -y update
apt-get -y install postgresql postgresql-contrib libpq-dev postgresql-server-dev-all postgresql-client-common

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
echo            "  Downloading and Osmosis schemas for APIDB and pg_snapshot"
echo            "  More Information Here:"
echo            "   http://wiki.openstreetmap.org/wiki/Database_schema#Database_Schema"
echo -e "\033[33m──━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━──\033[0m"

wget https://raw.github.com/openstreetmap/openstreetmap-website/master/db/structure.sql
wget https://raw.github.com/openstreetmap/osmosis/master/package/script/pgsnapshot_schema_0.6.sql

cd $cur_dir
echo -e "\033[32m"
echo "╔════════════════════════════════════════>"
echo "  Osmosis is now installed on "`hostname`
echo "╚════════════════════════════════════════>"
echo -e "\033[0m"
exit
