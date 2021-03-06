--upsert_way
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
    v_user_id bigint;
    v_res boolean;
  BEGIN 
    -- Set some values
      v_timestamp := now();
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

    -- Insert into the ways table  
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
    
    RETURN (v_id, v_new_id, v_new_version);
    END;
$upsert_way$ LANGUAGE plpgsql;
