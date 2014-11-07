#!/bin/bash
echo "╔══════════════════════════════════╗"
echo "   Installing postgresql 9.3 and PostGIS 2.1"
echo "╚══════════════════════════════════╝"

# Set up user information
echo "╔══════════════════════════════════════════════╗"
echo "  Set a UNIX password for the postgres user"
echo "╚══════════════════════════════════════════════╝"
sudo id -u postgres &>/dev/null || useradd postgres
sudo passwd postgres

echo    "╔════════════════════════════════════════════════════════════════════════════╗"
read -p "  What do you want to postgres database password to be?: (default: postgres): " postgres_pw
if [[ $postgres_pw == "" ]]; then
  postgres_pw=postgres
fi

wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
dist_name=`lsb_release -a 2> /dev/null | grep 'Codename:' | perl -pe "s/Codename:\s{1,}(.+)/\1/g"`
source_list="/etc/apt/sources.list.d/postgresql.list"
repo_name="http://apt.postgresql.org/pub/repos/apt/ $dist_name-pgdg main"
if [ -e "/etc/apt/sources.list.d/postgresql.list" ]; then
  # Check if we've already added this line
  contains_repo=`grep -r "$repo_name" "$source_list"`
  if [ -z "$contains_repo" ]; then
    sudo sh -c "echo \"deb $repo_name\" >> $source_list"
  fi
else
  sudo sh -c "echo \"deb $repo_name\" > $source_list"
fi
apt-get -y update
apt-get -y install postgresql postgresql-contrib postgis postgresql-9.3-postgis-2.1
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$postgres_pw';"

echo "╔══════════════════════════════════════════════╗"
echo "  postgresql 9.3 and PostGIS 2.1 installed!"
echo "╚══════════════════════════════════════════════╝"

