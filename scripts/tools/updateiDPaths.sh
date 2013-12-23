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

oldKey=5A043yRSEugj4DJ5TljuapfnrflWDte8jTOcWLlT
oldSecret=aB3jKq1TRsCOUrfOIZ6oQMEDmv2ptV76PA54NGLL
oldDevKey=zwQZFivccHkLs3a8Rq5CoS412fE5aPCXDw9DZj7R
oldDevSecret=aMnOOCwExO2XYtRVWJ1bI9QOdqh1cay2UgpbhA6p

# TODO: Pull the new keys from the config file
newKey=g3cmPe2OSqxkDmSIi8tOZjG4s1DYQtgtyYOOq1yx
newSecret=VaqYSfpCGFOletdeDaPanfrpbrZbQh38ytBLo3mX

# New URL
if [[ $newPort == "80" ]]; then
  site=$newPath
else
  site=$newPath":"$newPort
fi

# index.html
indexPath=$id_dir"/index.html"
sed -i "s/\"http:\/\/www.openstreetmap.org\",/\"http:\/\/$site\",/g" $indexPath
sed -i "s/$oldKey/$newKey/g" $indexPath
sed -i "s/$oldSecret/$newSecret/g" $indexPath

sed -i "s/\"http:\/\/api06.dev.openstreetmap.org\",/\"http:\/\/$site\",/g" $indexPath
sed -i "s/$oldDevKey/$newKey/g" $indexPath
sed -i "s/$oldDevSecret/$newSecret/g" $indexPath

# connection.js
connectionPath=$id_dir"/js/id/core/connection.js"
sed -i "s/'http:\/\/www.openstreetmap.org',/'http:\/\/$site',/g" $connectionPath
sed -i "s/$oldKey/$newKey/g" $connectionPath
sed -i "s/$oldSecret/$newSecret/g" $connectionPath
