#!/bin/bash
echo "╔══════════════════════════════════╗"
echo "     Installing postgresql 9.3"
echo "╚══════════════════════════════════╝"

wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" >> /etc/apt/sources.list.d/postgresql.list'
apt-get -y update
apt-get -y install postgresql-9.3 postgresql-contrib-9.3 libpq-dev postgresql-server-dev-all postgresql-client-common

# Set up user information
echo "╔══════════════════════════════════════════════╗"
echo "  Set a UNIX password for the postgres user"
echo "╚══════════════════════════════════════════════╝"

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

