CREATE OR REPLACE FUNCTION upsert_relation(
  bigint,
  integer,
  boolean,
  json,
  json
) RETURNS diffResult AS $upsert_relation$
  DECLARE
    v_id ALIAS FOR $1;
    v_changeset ALIAS FOR $2;
    v_visible ALIAS FOR $3;
    v_members ALIAS FOR $4;
    v_tags ALIAS FOR $5;
    v_timestamp timestamp without time zone;
    v_redaction_id integer;
    v_new_id bigint;
    v_new_version bigint;
  BEGIN
    -- Set some values
      v_timestamp := now();

    -- Determine if there needs to be a new relation and new verison
    SELECT
      COALESCE((
        SELECT
          relation_id
        FROM
          relations
        WHERE
          relation_id = v_id
        LIMIT 1
      ), (
        SELECT
          nextval('relation_id_seq')
      )) AS new_id,
      COALESCE((
        SELECT
          MAX(version)
        FROM
          relations
        WHERE
          relation_id = v_id
        GROUP BY
          relation_id
        ), 0)
        +1 AS new_version
    INTO
      v_new_id,
      v_new_version;

  -- Delete the current way nodes and tags
    DELETE from current_relation_tags where relation_id = v_new_id;
    DELETE from current_relation_members where relation_id = v_new_id;
    DELETE from current_relations where id = v_new_id;

    INSERT INTO
      relations (
        relation_id,
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
      current_relations (
        id,
        changeset_id,
        timestamp,
        visible,
        version
      ) VALUES (
        v_new_id,
        v_changeset,
        v_timestamp,
        v_visible,
        v_new_version
      );  

    -- Tags
    INSERT INTO
      relation_tags (
      SELECT
        v_new_id AS relation_id,
        k,
        v,
        v_new_version AS version
      FROM
        json_populate_recordset(
          null::relation_tags,
          v_tags
        )
      );
    INSERT INTO
      current_relation_tags (
      SELECT
        v_new_id AS relation_id,
        k,
        v
      FROM
        json_populate_recordset(
          null::current_relation_tags,
          v_tags
        )
      );

      -- Associated Members
      INSERT INTO
       relation_members (
       SELECT
         v_new_id AS relation_id,
         member_type as member_type,
         member_id as member_id,
         member_role as member_role,
         v_new_version AS version,
         sequence_id as sequence_id
       FROM
         json_populate_recordset(
           null::relation_members,
           v_members
         )
       );

      INSERT INTO
       current_relation_members (
       SELECT
         v_new_id AS relation_id,
         member_type as member_type,
         member_id as member_id,
         member_role as member_role,
         sequence_id as sequence_id
       FROM
         json_populate_recordset(
           null::current_relation_members,
           v_members
         )
       );

    RETURN (v_id, v_new_id, v_new_version);
    END;
$upsert_relation$ LANGUAGE plpgsql;
