CREATE OR REPLACE FUNCTION nps_get_value(text, json)
  RETURNS text AS
$BODY$
  DECLARE
    v_key ALIAS FOR $1;
    v_tags ALIAS FOR $2;
    v_value text;
    BEGIN

    SELECT v FROM
     (
       SELECT
         tag->>'k' as k,
         tag->>'v' as v
       FROM
         json_array_elements(v_tags) as tag
     ) tags
     WHERE
       tags.k = v_key
     LIMIT 1
       into v_value;

    RETURN v_value;
    END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

 CREATE OR REPLACE FUNCTION nps_update_value(text, text, json)
  RETURNS json AS
$BODY$
  DECLARE
    v_key ALIAS FOR $1;
    v_value ALIAS FOR $2;
    v_tags ALIAS FOR $3;
    v_new_json JSON;
    BEGIN
    
    IF v_value IS NOT NULL THEN
      SELECT
        json_agg(result)
      FROM (
        (
          SELECT k,v FROM (
            SELECT
              tag->>'k' as k,
              tag->>'v' as v
            FROM
              json_array_elements(
                v_tags::json
              ) as tag
          ) tags
          WHERE
            tags.k != v_key
        )
        UNION (
          SELECT k,v FROM (
            SELECT
              v_key as k,
              v_value as v
          ) tags
        )
      ) result
          INTO
            v_new_json;
    ELSE
      v_new_json := v_tags;
    END IF;

    RETURN v_new_json;
    END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

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
  RETURNS text AS
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

    RETURN lower(v_unitcode);
    END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION nps_get_unitcode(json)
  RETURNS text AS
$BODY$
  DECLARE
    v_json ALIAS FOR $1;
    v_lat integer;
    v_lon integer;
    v_unitcode text;
    BEGIN
      v_lat := (v_json->>'latitude')::integer;
      v_lon := (v_json->>'longitude')::integer;
      v_unitcode := nps_get_unitcode(v_lat, v_lon);

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

CREATE OR REPLACE FUNCTION nps_get_relation_center(json)
  RETURNS json AS
$BODY$
  DECLARE
    v_members ALIAS FOR $1;
    v_coords json;
  BEGIN

    --TODO: This doesn't support relations with nodes
    SELECT
      row_to_json(result)
    FROM (
      SELECT
          avg(current_nodes.latitude)::int as latitude,
          avg(current_nodes.longitude)::int as longitude
      FROM
        current_nodes
      WHERE
        id IN (
          SELECT
            node_id
          FROM (
            json_populate_recordset(
              null::relation_members,
              v_members
            ) this_obj JOIN
            current_way_nodes ON
            this_obj.member_id = current_way_nodes.way_id
          )
        )
      ) result
    INTO
      v_coords;

  RETURN v_coords;
  END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
