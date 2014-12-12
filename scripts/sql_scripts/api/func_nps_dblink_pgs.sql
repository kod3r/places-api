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
        'dbname=poi_pgs user=postgres password=postgres',
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
        'dbname=poi_pgs user=postgres password=postgres',
        v_sql
      ) AS pgs(res text) into v_res;

    RETURN v_res;
  END;
$nps_dblink_pgs_text$ LANGUAGE plpgsql;
