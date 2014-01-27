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

    -- Update the pgsnapshot view
    SELECT res FROM dblink('dbname=poi_pgs', 'select * from pgs_upsert_node(' || quote_literal(v_new_id) || ', ' || quote_literal(v_lat) || ', ' || quote_literal(v_lon) || ', ' || quote_literal(v_changeset) || ', ' || quote_literal(v_visible) || ', ' || quote_literal(v_timestamp) || ', ' || quote_literal(v_tags) || ', ' || quote_literal(v_new_version) || ', ' || quote_literal(v_user_id) || ')') as pgs(res boolean) into v_res;

    RETURN (v_id, v_new_id, v_new_version);
    END;
$upsert_node$ LANGUAGE plpgsql;
