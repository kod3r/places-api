--DROP FUNCTION new_session(bigint);
CREATE OR REPLACE FUNCTION close_changeset(
  bigint
) RETURNS boolean AS $close_changeset$

 DECLARE
    v_changeset_id ALIAS FOR $1;
    v_return_vals boolean[];
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
    
  -- Get Changed Ways
  SELECT
    array_agg((SELECT res FROM nps_dblink_pgs('select * from nps_pgs_update_o2p(' || quote_literal("changedWays"."way_id") || ', ' || quote_literal('W') || ')') as res))
  FROM (
    SELECT
      DISTINCT "way_id"
    FROM
      "nodes" JOIN "way_nodes" ON
        "nodes"."node_id" = "way_nodes"."node_id"
    WHERE
      "nodes"."changeset_id" = v_changeset_id AND
      way_id NOT IN (
        SELECT
          "ways"."way_id"
        FROM
          "ways"
        WHERE
          "ways"."changeset_id" = "nodes"."changeset_id"
      )
  ) "changedWays"
  INTO v_return_vals;
  
  -- Get Changed Relations
  SELECT
    array_agg((SELECT res FROM nps_dblink_pgs('select * from nps_pgs_update_o2p(' || quote_literal("changedRelations"."relation_id") || ', ' || quote_literal('R') || ')') as res))
  FROM (
    SELECT
      DISTINCT "relation_members"."relation_id"
    FROM
      "nodes" JOIN "relation_members" ON
        "nodes"."node_id" = "relation_members"."member_id"
    WHERE
      lower("relation_members"."member_type"::text) = 'node' AND
      "nodes"."changeset_id" = v_changeset_id AND
      "relation_members"."member_id" NOT IN (
        SELECT
          "relations"."relation_id"
        FROM
          "relations"
        WHERE
          "relations"."changeset_id" = "nodes"."changeset_id"
       )
    UNION
    SELECT
      DISTINCT "relation_members"."relation_id"
    FROM
      "ways" JOIN "relation_members" ON
        "ways"."way_id" = "relation_members"."member_id"
    WHERE
      lower("relation_members"."member_type"::text) = 'way' AND
      "ways"."changeset_id" = v_changeset_id AND
      "relation_members"."member_id" NOT IN (
        SELECT
          "relations"."relation_id"
        FROM
          "relations"
        where
          "relations"."changeset_id" = "ways"."changeset_id"
      )
  ) "changedRelations"
  INTO v_return_vals;

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

    RETURN v_changeset_exists;
  END;
  
$close_changeset$ LANGUAGE plpgsql;
