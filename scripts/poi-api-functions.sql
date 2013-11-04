-- nodes
CREATE SEQUENCE node_id_seq;
SELECT setval('node_id_seq', (SELECT max(node_id)+1 from nodes));

-- ways
CREATE SEQUENCE way_id_seq;
SELECT setval('way_id_seq', (SELECT max(way_id)+1 from ways));

-- changesets
SELECT setval('changesets_id_seq', (SELECT max(id)+1 from changesets));

-- node update/insert function
CREATE TYPE diffResult AS (old_id bigint, new_id bigint, new_version bigint);

CREATE OR REPLACE FUNCTION upsert_node(
  bigint,
  integer,
  integer,
  bigint,
  json
) RETURNS diffResult AS $upsert_node$
  DECLARE
    v_id ALIAS FOR $1;
    v_lat ALIAS FOR $2;
    v_lon ALIAS FOR $3;
    v_changeset ALIAS FOR $4;
    v_tags ALIAS FOR $5;
    v_visible boolean;
    v_timestamp timestamp without time zone;
    v_tile bigint;
    v_redaction integer;
    v_new_id bigint;
    v_new_version bigint;
    BEGIN
      -- Set some values
        v_visible := true;
        v_timestamp := now();
        v_tile := tile_for_point(v_lat, v_lon);

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

    RETURN (v_id, v_new_id, v_new_version);
    END;
$upsert_node$ LANGUAGE plpgsql;
