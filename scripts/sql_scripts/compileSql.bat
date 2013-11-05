echo "-- Compiled on "`date`  > compiled.sql
echo "" >> compiled.sql

echo "-- sequences" >> compiled.sql
for file in `ls sequence*.sql`; do
  echo "-- $file" >> compiled.sql
  cat $file >> compiled.sql
done
echo "-- types" >> compiled.sql
for file in `ls type*.sql`; do
  echo "-- $file" >> compiled.sql
  cat $file >> compiled.sql
done
echo "-- views" >> compiled.sql
for file in `ls view*.sql`; do
  echo "-- $file" >> compiled.sql
  cat $file >> compiled.sql
done
echo "-- functions" >> compiled.sql
for file in `ls func*.sql`; do
  echo "-- $file" >> compiled.sql
  cat $file >> compiled.sql
done

