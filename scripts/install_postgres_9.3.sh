#!/bin/bash
echo "╔══════════════════════════════════╗"
echo "     Installing postgresql 9.3"
echo "╚══════════════════════════════════╝"

# Set up user information
echo "╔══════════════════════════════════════════════╗"
echo "  Set a UNIX password for the postgres user"
echo "╚══════════════════════════════════════════════╝"
read -p 'Press [Enter] key to continue...'
sudo passwd postgres

echo    "╔════════════════════════════════════════════════════════════════════════════╗"
read -p "  What do you want to postgres database password to be?: (default: postgres): " postgres_pw
if [[ $postgres_pw == "" ]]; then
  postgres_pw=postgres
fi

wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" >> /etc/apt/sources.list.d/postgresql.list'
apt-get -y update
apt-get -y install postgresql-9.3 postgresql-contrib-9.3 libpq-dev postgresql-server-dev-all postgresql-client-common
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$postgres_pw';"

echo "╔══════════════════════════════════════════════╗"
echo "          postgresql 9.3 installed!"
echo "╚══════════════════════════════════════════════╝"

