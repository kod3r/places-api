newPath=$1
newPort=$2
id_dir=$3

# This can also be done with the following command:
# grep -rl '$ORIG' $DIR | xargs sed -i 's/$ORIG/$NEW/g'
# Although not as cleanly

# Prompt the user for the input if they didn't offer any
if [[ $newPath == "" ]]; then
  echo
  echo    "╔════════════════════════════════════════════════════════════════════════════╗"
  echo "Your computer current has the following ip address(es):"
  ifconfig | awk -v RS="\n\n" '{ for (i=1; i<=NF; i++) if ($i == "inet" && $(i+1) ~ /^addr:/) address = substr($(i+1), 6); if (address != "127.0.0.1") printf "\033[34m%s\033[0m\t\033[33m%s\033[0m\n", $1, address }'
  echo
  echo    "╔════════════════════════════════════════════════════════════════════════════╗"
  echo    "  Path"
  read -p "  What is the address where the API will be hosted? (default: localhost): " newPath
  if [[ $newPath == "" ]]; then
    newPath=localhost
  fi
fi

if [[ $newPort == "" ]]; then
  echo    "╔════════════════════════════════════════════════════════════════════════════╗"
  echo    "  Port"
  read -p "  What is the port where the API will be hosted? (default: 80): " newPort
  if [[ $newPort == "" ]]; then
    newPort=80
  fi
fi

if [[ $id_dir == "" ]]; then
  echo    "╔════════════════════════════════════════════════════════════════════════════╗"
  echo    "  iD directory"
  read -p "  What is the directory where this script can find iD? (required): " id_dir
  if [[ $id_dir == "" ]]; then
    exit
  fi
fi

# Define the files that need updating
updateFiles=($id_dir"/index.html" $id_dir"/js/id/core/connection.js")
# TODO: Pull the new keys from the config file, maybe?
newKey=g3cmPe2OSqxkDmSIi8tOZjG4s1DYQtgtyYOOq1yx
newSecret=VaqYSfpCGFOletdeDaPanfrpbrZbQh38ytBLo3mX

oldKey=5A043yRSEugj4DJ5TljuapfnrflWDte8jTOcWLlT
oldSecret=aB3jKq1TRsCOUrfOIZ6oQMEDmv2ptV76PA54NGLL
oldDevKey=zwQZFivccHkLs3a8Rq5CoS412fE5aPCXDw9DZj7R
oldDevSecret=aMnOOCwExO2XYtRVWJ1bI9QOdqh1cay2UgpbhA6p

# New URL
if [[ $newPort == "80" ]]; then
  site=$newPath
else
  site=$newPath":"$newPort
fi

updateFiles=($id_dir"index.html" $id_dir"js/id/core/connection.js")

for filename in "${updateFiles[@]}"; do
  # replace the URLs
  perl -i -pe "s/(\"?url.+?['\"]https?:\/\/)\K.+?(['\",].+)/$site\2/g" $filename

  # replace the keys
  sed -i "s/$oldKey/$newKey/g" $filename
  sed -i "s/$oldSecret/$newSecret/g" $filename
  sed -i "s/$oldDevKey/$newKey/g" $filename
  sed -i "s/$oldDevSecret/$newSecret/g" $filename

done
