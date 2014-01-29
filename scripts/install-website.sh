echo -e "\033[34m"
echo "╔═════════════════════════════════════════════════════════════════╗"
echo "║  Installing the poi-api website                                 ║"
echo "╟─────────────────────────────────────────────────────────────────╢"
echo "║  More information can be found here:                            ║"
echo "║     https://github.com/nationalparkservice/poi-api              ║"
echo "╚═════════════════════════════════════════════════════════════════╝"
echo -e "\033[0m"
echo ""

# Prompt the user for these
this_dir=`pwd`
website_dir=$this_dir/poi-website

mkdir -p $website_dir/node_modules

# Clone our repo into that dir
cd $website_dir/node_modules
git clone https://github.com/nationalparkservice/poi-api.git
git clone https://github.com/nationalparkservice/iD.git
cd $this_dir

# Move the examples to the root dir
cp $website_dir/node_modules/poi-api/examples/app.js $website_dir
cp -r $website_dir/node_modules/poi-api/examples/views $website_dir
cp $website_dir/node_modules/poi-api/package.json $website_dir/package.json

# Create the config file
cp $website_dir/node_modules/poi-api/example.config.json $website_dir/node_modules/poi-api/config.json

# ASK FOR YOUR IP ADDRESS
echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "  Your machine has the following IP Addresses:"
ifconfig | awk -v RS="\n\n" '{ for (i=1; i<=NF; i++) if ($i == "inet" && $(i+1) ~ /^addr:/) address = substr($(i+1), 6); if (address != "127.0.0.1") printf "\033[34m%s\033[0m\t\033[33m%s\033[0m\n", $1, address }'
read -p "  What IP address do you want use for your server?: " ipaddress
if [[ $ipaddress == "" ]]; then
    ipaddress=127.0.0.1
fi

echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo    "  PORT"
read -p "  What port would you like to use for your web server? (default: 3000): " port
if [[ $ipaddress == "" ]]; then
    port=3000
fi

echo    "╔════════════════════════════════════════════════════════════════════════════╗"
echo    "  DATABASE API"
read -p "  What do you want your API database to be named? (default: osm_api): " dbnameapi
if [[ $dbnameapi == "" ]]; then
  dbnameapi=osm_api
fi

echo    "╔════════════════════════════════════════════════════════════════════════════╗"
echo    "  DATABASE Rendering (pgsnapshot)"
read -p "  What do you want your rendering database to be named? (default: osm_pgs): " dbnamepgs
if [[ $dbnamepgs == "" ]]; then
  dbname=osm_pgs
fi

echo    "╔════════════════════════════════════════════════════════════════════════════╗"
echo    "  USERNAME"
read -p "  What do you want your database username to be? (default: osm): " user
if [[ $user == "" ]]; then
  user=osm
fi

echo    "╔════════════════════════════════════════════════════════════════════════════╗"
echo    "  PASSWORD"
read -p "  What do you want your database password to be? (default: osm): " pass
if [[ $pass == "" ]]; then
  pass=osm
fi

# install the other modules
echo    "╔════════════════════════════════════════════════════════════════════════════╗"
echo    "  Installing the required modules"
cd $website_dir
node -e "console.log(JSON.stringify(`cat package.json`.dependencies, null, 2));"
npm install
cd $this_dir

# Set up iD to work with the new IP
bash $website_dir/node_modules/poi-api/scripts/tools/updateiDPaths.sh $ipaddress $port $website_dir/node_modules/iD/

# Add the DOMParser to the osm-and-geojson project
bash $website_dir/node_modules/poi-api/scripts/tools/addDomParser.sh $website_dir/node_modules/osm-and-geojson

# Set up this app to use the specified port
sed -i "s/process.env.PORT || 3000);/process.env.PORT || $port);/g" $website_dir/app.js

# ASK FOR USER/PASS/DB name
sed -i "s/\"username\": \"USERNAME\"/\"username\": \"$user\"/g" $website_dir/node_modules/poi-api/config.json
sed -i "s/\"password\": \"PASSWORD\"/\"password\": \"$pass\"/g" $website_dir/node_modules/poi-api/config.json
sed -i "s/\"api\": \"API_DATABASE_NAME\"/\"name\": \"$dbnameapi\"/g" $website_dir/node_modules/poi-api/config.json
sed -i "s/\"pgs\": \"RENDERING_DATABASE_NAME\"/\"name\": \"$dbnamepgs\"/g" $website_dir/node_modules/poi-api/config.json

# WOULD YOU LIKE TO INSTALL POSTGRES 9.3?
echo    "╔════════════════════════════════════════════════════════════════════════════╗"
read -p "  Would you like to Install PostGres 9.3 and PostGis 2.1? (y/n): " REPLY
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
  sudo bash $website_dir/node_modules/poi-api/scripts/install_postgres_9.3.sh
fi

# WOULD YOU LIKE TO LOAD DATA INTO YOUR DB?
echo    "╔════════════════════════════════════════════════════════════════════════════╗"
read -p "  Would you like to create your osm databases ($dbnameapi and $dbnamepgs)? (y/n): " REPLY
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
  cd $website_dir/node_modules/poi-api/scripts/
  sudo bash create_osm_db.sh $user $pass $dbnameapi $dbnamepgs
  cd $this_dir
fi

sudo chown -R `whoami`:`whoami` $website_dir
cd $this_dir

echo -e "\033[34m"
echo "╔═════════════════════════════════════════════════════════════════╗"
echo "║  The poi-api website has been installed                         ║"
echo "╟─────────────────────────────────────────────────────────────────╢"
echo "║  You can now run it with the command:                           ║"
echo "║    node $website_dir/app.js"
echo "╚═════════════════════════════════════════════════════════════════╝"
echo -e "\033[0m"
echo ""
sudo chown -R `whoami`:`whoami` $website_dir
exit
