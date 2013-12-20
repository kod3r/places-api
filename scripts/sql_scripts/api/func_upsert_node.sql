DROP FUNCTION upsert_node(bigint, integer, integer, bigint, boolean, json);
CREATE OR REPLACE FUNCTION upsert_node(
  bigint,
  integer,
  integer,
  bigint,
  boolean,
  json
) RETURNS diffResult AS $upsert_node$
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
    BEGIN
      -- Set some values
        v_timestamp := now();
        v_tile := tile_for_point(v_lat, v_lon);
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

  -- Delete the current nodes and tags
    DELETE from current_way_nodes where way_id IN (SELECT way_id from current_way_nodes WHERE node_id = v_new_id) and node_id  = v_new_id;
    DELETE from current_node_tags where node_id = v_new_id;
    DELETE from current_nodes where id = v_new_id;

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
    INSERT INTO
      current_nodes (
        id,
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
    INSERT INTO
      current_node_tags (
      SELECT
        v_new_id AS node_id,
        k,
        v
      FROM
        json_populate_recordset(
          null::current_node_tags,
          v_tags
        )
      );
    INSERT INTO
      current_way_nodes (
      SELECT
        way_id,
        node_id,
        sequence_id
      FROM
        way_nodes
      WHERE
        way_id IN (SELECT way_id from way_nodes WHERE node_id = v_new_id) AND
        version = (
          SELECT
            MAX(version)
          FROM
            way_nodes
          WHERE
            way_id IN (SELECT way_id from way_nodes WHERE node_id = v_new_id)
        ) AND
        node_id = v_new_id
      );

    -- Update the pgsnapshot view
    SELECT res FROM dblink('dbname=poi_pgs', 'select * from pgs_upsert_node(' || quote_literal(v_new_id) || ', ' || quote_literal(v_lat) || ', ' || quote_literal(v_lon) || ', ' || quote_literal(v_changeset) || ', ' || quote_literal(v_visible) || ', ' || quote_literal(v_timestamp) || ', ' || quote_literal(v_tags) || ', ' || quote_literal(v_new_version) || ', ' || quote_literal(v_user_id) || ')') as pgs(res boolean) into v_res;

    RETURN (v_id, v_new_id, v_new_version);
    END;
$upsert_node$ LANGUAGE plpgsql;
