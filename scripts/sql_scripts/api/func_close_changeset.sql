--DROP FUNCTION new_session(bigint);
CREATE OR REPLACE FUNCTION close_changeset(
  bigint
) RETURNS boolean AS $close_changeset$

 DECLARE
    v_changeset_id ALIAS FOR $1;
    v_return_values boolean[];
    v_changeset_exists boolean;
    BEGIN
  
  -- Close the changeset and assign its number of changes
  UPDATE
    "changesets"
  SET
    "closed_at" = NOW()::timestamp without time zone,
    "num_changes" = (
      SELECT sum(counts.count) FROM (
        SELECT count(*) FROM nodes WHERE changeset_id = changesets.id
        UNION
        SELECT count(*) FROM ways WHERE changeset_id = changesets.id
        UNION
        SELECT count(*) FROM relations WHERE changeset_id = changesets.id
      ) counts)
  WHERE
    "id" = v_changeset_id;
  
  -- Just verify that the changeset was added
  SELECT
    EXISTS(
      SELECT
        "changesets"."id"
      FROM
        "changesets"
      WHERE
        "changesets"."id" = v_changeset_id
    )
  INTO v_changeset_exists;
  
  -- Update the changeset in the pgsnapshot db (this no longer fully renders the data, just copies it)
  SELECT res FROM nps_dblink_pgs('SELECT count(*)>0 FROM pgs_update_changeset(' || quote_literal(v_changeset_id) || ')') as res INTO v_return_values;

    RETURN v_changeset_exists;
  END;
$close_changeset$ LANGUAGE plpgsql;
