--upsert_relation
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
    v_user_id bigint;
    v_res boolean;
    v_uuid_field text;
    v_uuid text;
    v_unitcode_field text;
    v_unitcode text;
  BEGIN
    -- Set some values
      v_timestamp := now();
      v_uuid_field := 'nps:places_uuid';
      v_unitcode_field := 'nps:unit_code';
      SELECT
        changesets.user_id
      FROM
        changesets
      WHERE
        changesets.id = v_changeset
      INTO
        v_user_id;

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

    -- uuid
      v_uuid := nps_get_value(v_uuid_field, v_tags);
      IF v_uuid IS NULL THEN
       SELECT
         nps_update_value(v_uuid_field, uuid_generate_v4()::text, v_tags)
       INTO
         v_tags;
      END IF;

    -- Unit Code
      v_unitcode := nps_get_value(v_unitcode_field, v_tags);
      IF v_unitcode IS NULL THEN
       SELECT
         nps_update_value(v_unitcode_field, nps_get_unitcode(nps_get_relation_center(v_members)), v_tags)
       INTO
         v_tags;
      END IF;

    -- Insert into the relations table  
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

    -- Update the pgsnapshot view
        SELECT res FROM nps_dblink_pgs('select * from pgs_upsert_relation(' || quote_literal(v_new_id) || ', ' || quote_literal(v_changeset) || ', ' || quote_literal(v_visible) || ', ' || quote_literal(v_members) || ', ' || quote_literal(v_tags) || ', ' || quote_literal(v_timestamp) || ', '  || quote_literal(v_new_version) || ', ' || quote_literal(v_user_id) || ')') as res into v_res;

    RETURN (v_id, v_new_id, v_new_version);
    END;
$upsert_relation$ LANGUAGE plpgsql;
