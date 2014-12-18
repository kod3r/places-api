-- Convert JSON to hstore
CREATE OR REPLACE FUNCTION public.json_to_hstore(
  json
)
  RETURNS hstore AS $json_to_hstore$
DECLARE
  v_json ALIAS for $1;
  v_hstore HSTORE;
BEGIN
SELECT
  hstore(array_agg(key), array_agg(value))
FROM
 json_each_text(v_json)
INTO
  v_hstore;

 RETURN v_hstore;
END;
$json_to_hstore$
LANGUAGE plpgsql;

--DROP FUNCTION nps_dblink_pgs(text);
CREATE OR REPLACE FUNCTION nps_dblink_pgs(
  text
) RETURNS boolean AS $nps_dblink_pgs$
  DECLARE
    v_sql ALIAS FOR $1;
    v_res boolean;
    BEGIN

    SELECT
      res
    FROM
      dblink(
        'dbname=poi_pgs user=postgres',
        v_sql
      ) AS pgs(res boolean) into v_res;

    RETURN v_res;
  END;
$nps_dblink_pgs$ LANGUAGE plpgsql;


--DROP FUNCTION nps_dblink_pgs_text(text);
CREATE OR REPLACE FUNCTION nps_dblink_pgs_text(
  text
) RETURNS text AS $nps_dblink_pgs_text$
  DECLARE
    v_sql ALIAS FOR $1;
    v_res text;
    BEGIN

    SELECT
      res
    FROM
      dblink(
        'dbname=poi_pgs user=postgres',
        v_sql
      ) AS pgs(res text) into v_res;

    RETURN v_res;
  END;
$nps_dblink_pgs_text$ LANGUAGE plpgsql;
