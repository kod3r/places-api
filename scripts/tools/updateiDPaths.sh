newPath=$1
newPort=$2
id_dir=$3

if [[ $newPath == "" ]]; then
  echo    "╔════════════════════════════════════════════════════════════════════════════╗"
  echo    "  Path"
  read -p "  What is the address where the API will be hosted? (default: localhost): " user
  if [[ $newPath == "" ]]; then
    newPath=localhost
  fi
fi

if [[ $newPort == "" ]]; then
  echo    "╔════════════════════════════════════════════════════════════════════════════╗"
  echo    "  Port"
  read -p "  What is the port where the API will be hosted? (default: 80): " user
  if [[ $newPort == "" ]]; then
    newPort=80
  fi
fi

if [[ $id_dir == "" ]]; then
  echo    "╔════════════════════════════════════════════════════════════════════════════╗"
  echo    "  iD directory"
  read -p "  What is the directory where this script can find iD? (default: ??): " user
  if [[ $id_dir == "" ]]; then
    id_dir=80
  fi
fi

# TODO: Pull the new keys from the config file
oldKey=5A043yRSEugj4DJ5TljuapfnrflWDte8jTOcWLlT
oldSecret=aB3jKq1TRsCOUrfOIZ6oQMEDmv2ptV76PA54NGLL
newKey=g3cmPe2OSqxkDmSIi8tOZjG4s1DYQtgtyYOOq1yx
newSecret=VaqYSfpCGFOletdeDaPanfrpbrZbQh38ytBLo3mX

# index.html
sed -i "s/\"http:\/\/www.openstreetmap.org\",/\"http:\/\/$ipaddress:$port\",/g" $website_dir/node_modules/iD/index.html
sed -i "s/$oldKey/$newKey/g" $website_dir/node_modules/iD/index.html
sed -i "s/$oldSecret/$newSecret/g" $website_dir/node_modules/iD/index.html

# connection.js
sed -i "s/'http:\/\/www.openstreetmap.org',/'http:\/\/$ipaddress:$port',/g" $website_dir/node_modules/iD/js/id/core/connection.js
sed -i "s/$oldKey/$newKey/g" $website_dir/node_modules/iD/js/id/core/connection.js
sed -i "s/$oldSecret/$newSecret/g" $website_dir/node_modules/iD/js/id/core/connection.js


