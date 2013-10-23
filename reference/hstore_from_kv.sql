create or replace function hstore_from_kv (tablename varchar, idfield varchar, id bigint, version bigint) returns hstore language plpgsql as $$
declare
  keyQuery varchar;
  keyQueryArray varchar;
  crossQuery varchar;
  hstoreQuery varchar;
  hstoreVal hstore;
  keys varchar;
  keysTypes varchar;
begin
  keyQuery = 'SELECT ''"''||k||''" varchar'' as k FROM '||tablename||' WHERE '||idfield||' = '||id||' and version = '||version||' order by k';
  keyQueryArray= 'SELECT STRING_AGG(k,'','') FROM ('||keyQuery||') AS keyQueryArray;';
  execute keyQueryArray into keysTypes;

  keyQuery = 'SELECT ''"''||k||''"'' as k FROM '||tablename||' WHERE '||idfield||' = '||id||' and version = '||version||' order by k';
  keyQueryArray= 'SELECT STRING_AGG(k,'','') FROM ('||keyQuery||') AS keyQueryArray;';
  execute keyQueryArray into keys;

  crossQuery = 'SELECT '||keys||' from CROSSTAB(''select '||idfield||', k, v  from '||tablename||' where '||idfield||'='||id||' and version = '||version||' order by k'') as ct ("id" bigint, '||keysTypes||')';

  hstoreQuery = 'select hstore(t) from ('||crossQuery||') as t;';
  execute hstoreQuery into hstoreVal;

  return hstoreVal;
end;
$$;
