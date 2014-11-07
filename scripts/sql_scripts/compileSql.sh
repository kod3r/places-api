inputFiles=('sequence' 'type' 'view' 'func')

find . -type d -print0 | while IFS= read -r -d '' dir
do
  if [ "$dir" != "." ];
  then
    outputFile=$dir"_compiled.sql"

    echo "-- Compiled on "`date`  > $outputFile
    echo "" >> $outputFile

    for i in "${inputFiles[@]}"
    do
      query=$dir/$i*.sql
      echo "query: "$query
      echo "outputFile: "$outputFile
      if [ -f "$query" ];
      then
        echo "-- "$i" --" >> $outputFile
        for file in `ls $query`; do
          cat $file >> $outputFile
        done
      fi
    done
  fi
done
