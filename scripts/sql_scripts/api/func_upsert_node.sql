-- Function: upsert_node(bigint, integer, integer, bigint, boolean, json)

-- DROP FUNCTION upsert_node(bigint, integer, integer, bigint, boolean, json);

CREATE OR REPLACE FUNCTION upsert_node(bigint, integer, integer, bigint, boolean, json)
  RETURNS diffresult AS
$BODY$
  DECLARE
    v_id ALIAS FOR $1;
    v_lat ALIAS FOR $2;
    v_lon ALIAS FOR $3;
    v_changeset ALIAS FOR $4;
    v_visible ALIAS FOR $5;
    v_tags ALIAS FOR $6;
    v_timestamp timestamp without time zone;
    v_tile bigint;
    v_redaction integer;
    v_new_id bigint;
    v_new_version bigint;
    v_user_id bigint;
    v_res boolean;
    v_uuid text; -- if text is in this field, it will add a uuid field to new entries
    v_unitcode_field text;
    v_unitcode text;
    BEGIN
      -- Set some values
        v_timestamp := now();
        v_tile := tile_for_point(v_lat, v_lon);
        v_uuid := 'nps:places_uuid';
        v_unitcode_field := 'nps:alphacode';
        SELECT
          changesets.user_id
        FROM
          changesets
        WHERE
          changesets.id = v_changeset
        INTO
          v_user_id;

      -- Determine if there needs to be a new node and new verison
    SELECT
      COALESCE((
        SELECT
          node_id
        FROM
          nodes
        WHERE
          node_id = v_id
        LIMIT 1
      ), (
        SELECT
          nextval('node_id_seq')
      )) AS new_id,
      COALESCE((
        SELECT
          MAX(version)
        FROM
          nodes
        WHERE
          node_id = v_id
        GROUP BY
          node_id
        ), 0)
        +1 AS new_version
    INTO
      v_new_id,
      v_new_version;

    INSERT INTO
     nodes (
       node_id,
       latitude,
       longitude,
       changeset_id,
       visible,
       timestamp,
       tile,
       version
     ) VALUES (
       v_new_id,
       v_lat,
       v_lon,
       v_changeset,
       v_visible,
       v_timestamp,
       v_tile,
       v_new_version
     );
     
-- Tags
     INSERT INTO
       node_tags (
       SELECT
         v_new_id AS node_id,
         v_new_version AS version,
         k,
         v
       FROM
         json_populate_recordset(
           null::node_tags,
           v_tags
         )
       );

    IF length(v_uuid) > 0 AND v_new_version = 1 THEN
     INSERT INTO
       node_tags (
       SELECT
         v_new_id AS node_id,
         v_new_version AS version,
         v_uuid,
         uuid_generate_v4()
       );
       SELECT tag FROM api_current_nodes WHERE id = v_new_id INTO v_tags;
    END IF;

-- Unit Code
    SELECT v FROM
     (
       SELECT
         tag->>'k' as k,
         tag->>'v' as v
       FROM
         json_array_elements(v_tags) as tag
     ) tags
     WHERE
       tags.k = v_unitcode_field
     LIMIT 1
       into v_unitcode;
       
    IF v_unitcode IS NULL THEN
     SELECT code FROM nps_dblink_pgs_text('SELECT unit_code FROM render_park_polys WHERE ST_Within(ST_Transform(ST_SetSrid(ST_MakePoint(' || quote_literal(v_lon/10000000::float) || ', ' || quote_literal(v_lat/10000000::float) || '),4326),3857),poly_geom) ORDER BY minzoompoly DESC, area DESC LIMIT 1') as code into v_unitcode;
       IF v_unitcode IS NOT NULL THEN
       INSERT INTO
         node_tags (
         SELECT
	   v_new_id AS node_id,
	   v_new_version AS version,
	   v_unitcode_field,
	   v_unitcode
         );
       SELECT tag FROM api_current_nodes WHERE id = v_new_id INTO v_tags;
      END IF;
    END IF;

    -- Update the pgsnapshot view
    SELECT res FROM nps_dblink_pgs('select * from pgs_upsert_node(' || quote_literal(v_new_id) || ', ' || quote_literal(v_lat) || ', ' || quote_literal(v_lon) || ', ' || quote_literal(v_changeset) || ', ' || quote_literal(v_visible) || ', ' || quote_literal(v_timestamp) || ', ' || quote_literal(v_tags) || ', ' || quote_literal(v_new_version) || ', ' || quote_literal(v_user_id) || ')') as res into v_res;

    RETURN (v_id, v_new_id, v_new_version);
    END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION upsert_node(bigint, integer, integer, bigint, boolean, json)
  OWNER TO postgres;
