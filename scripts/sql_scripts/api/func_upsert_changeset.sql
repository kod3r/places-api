DROP FUNCTION upsert_changeset(bigint,bigint,json);
CREATE OR REPLACE FUNCTION upsert_changeset(
  bigint,
  bigint,
  json
) RETURNS json AS $upsert_changeset$
  DECLARE
    v_id ALIAS FOR $1;
    v_user ALIAS FOR $2;
    v_tags ALIAS FOR $3;
    v_timestamp timestamp without time zone;
    v_new_id bigint;
    v_return_json json;
    BEGIN
      -- Set some values
        v_timestamp := now();

      -- Determine if there needs to be a new changeset
    SELECT
      COALESCE((
        SELECT
          id
        FROM
          changesets
        WHERE
          id = v_id AND
          user_id = v_user AND
          created_at = closed_at
        LIMIT 1
      ), (
        SELECT
          nextval('changesets_id_seq')
      )) AS new_id
    INTO
      v_new_id;

    IF v_id != v_new_id THEN
      INSERT INTO
        changesets
      (
        id,
        user_id,
        created_at,
        closed_at
      ) VALUES (
        v_new_id,
        v_user,
        now(),
        now()
      );
    END IF;

    -- Remove the old tags for this changeset
    DELETE from changeset_tags where changeset_id = v_new_id;

    -- Tags
    INSERT INTO
      changeset_tags (
      SELECT
        v_new_id AS changeset_id,
        k,
        v
      FROM
        json_populate_recordset(
          null::changeset_tags,
          v_tags
        )
      );

      SELECT
        json_agg(changeset)
      FROM
      (
        SELECT
          *
        FROM
          api_changesets
        WHERE
          api_changesets.id = v_new_id
      ) changeset
      INTO
        v_return_json;

    RETURN v_return_json;
  END;
$upsert_changeset$ LANGUAGE plpgsql;
