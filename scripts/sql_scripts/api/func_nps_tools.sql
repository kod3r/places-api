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

CREATE OR REPLACE FUNCTION nps_get_unitcode(integer, integer)
  RETURNS json AS
$BODY$
  DECLARE
    v_lat ALIAS FOR $1;
    v_lon ALIAS FOR $2;
    v_unitcode text;
    BEGIN
      SELECT
        code
      FROM
        nps_dblink_pgs_text(
          'SELECT unit_code FROM render_park_polys WHERE ST_Within(ST_Transform(ST_SetSrid(ST_MakePoint(' || quote_literal(v_lon/10000000::float) || ', ' || quote_literal(v_lat/10000000::float) || '),4326),3857),poly_geom) ORDER BY minzoompoly DESC, area DESC LIMIT 1') as code
      INTO v_unitcode;

    RETURN v_unitcode;
    END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION nps_get_way_center(json)
  RETURNS json AS
$BODY$
  DECLARE
    v_nodes ALIAS FOR $1;
    v_coords JSON;
  BEGIN

    SELECT
      row_to_json(result)
    FROM (
      SELECT
        avg(current_nodes.latitude)::int as latitude,
        avg(current_nodes.longitude)::int as longitude
      FROM
        (
          SELECT
            node_id
          FROM
            json_populate_recordset(
              null::way_nodes,
              v_nodes
            )
        ) way_nodes JOIN current_nodes ON
        way_nodes.node_id = current_nodes.id
    ) result
    INTO
      v_coords;
      
  RETURN v_coords;
  END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
