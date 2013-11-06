CREATE OR REPLACE FUNCTION upsert_way(
  bigint,
  integer,
  boolean,
  json,
  json
) RETURNS diffResult AS $upsert_way$
  DECLARE
    v_id ALIAS FOR $1;
    v_changeset ALIAS FOR $2;
    v_visible ALIAS FOR $3;
    v_nodes ALIAS FOR $4;
    v_tags ALIAS FOR $5;
    v_timestamp timestamp without time zone;
    v_tile bigint;
    v_redaction_id integer;
    v_new_id bigint;
    v_new_version bigint;
  BEGIN 
    -- Set some value
      v_timestamp := now();

    -- Determine if there needs to be a new node and new verison
    SELECT
      COALESCE((
        SELECT
          way_id
        FROM
          ways
        WHERE
          way_id = v_id
        LIMIT 1
      ), (
        SELECT
          nextval('way_id_seq')
      )) AS new_id,
      COALESCE((
        SELECT
          MAX(version)
        FROM
          ways
        WHERE
          way_id = v_id
        GROUP BY
          way_id
        ), 0)
        +1 AS new_version
    INTO
      v_new_id,
      v_new_version;

  -- Delete the current way nodes and tags
    DELETE from current_way_nodes where way_id = v_new_id;
    DELETE from current_way_tags where way_id = v_new_id;
    DELETE from current_ways where id = v_new_id;

    INSERT INTO
      ways (
        way_id,
        changeset_id,
        timestamp,
        version,
        visible,
        redaction_id
      ) VALUES (
        v_new_id,
        v_changeset,
        v_timestamp,
        v_new_version,
        v_visible,
        v_redaction_id
      );    
    INSERT INTO
      current_ways (
        id,
        changeset_id,
        timestamp,
        version,
        visible
      ) VALUES (
        v_new_id,
        v_changeset,
        v_timestamp,
        v_new_version,
        v_visible
      );  

    -- Tags
    INSERT INTO
      way_tags (
      SELECT
        v_new_id AS way_id,
        k,
        v,
        v_new_version AS version
      FROM
        json_populate_recordset(
          null::way_tags,
          v_tags
        )
      );
    INSERT INTO
      current_way_tags (
      SELECT
        v_new_id AS way_id,
        k,
        v
      FROM
        json_populate_recordset(
          null::current_way_tags,
          v_tags
        )
      );

      -- Associated Nodes
      INSERT INTO
       way_nodes (
       SELECT
         v_new_id AS way_id,
         node_id as node_id,
         v_new_version AS version,
         sequence_id as sequence_id
       FROM
         json_populate_recordset(
           null::way_nodes,
           v_nodes
         )
       );
      INSERT INTO
       current_way_nodes (
       SELECT
         v_new_id AS way_id,
         node_id as node_id,
         sequence_id as sequence_id
       FROM
         json_populate_recordset(
           null::way_nodes,
           v_nodes
         )
       );

    RETURN (v_id, v_new_id, v_new_version);
    END;
$upsert_way$ LANGUAGE plpgsql;
