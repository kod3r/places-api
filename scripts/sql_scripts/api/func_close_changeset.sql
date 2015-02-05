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
    
-- Update Changed nodes in pgs
  SELECT array_agg((SELECT
    res
  FROM
    nps_dblink_pgs(
      'select * from pgs_upsert_node(' || quote_literal("changed_nodes"."id") || ', ' || quote_literal("changed_nodes"."lat") || ', ' || quote_literal("changed_nodes"."lon") || ', ' || quote_literal("changed_nodes"."changeset_id") || ', ' || quote_literal("changed_nodes"."visible") || ', ' || quote_literal("changed_nodes"."timestamp") || ', ' || quote_literal("changed_nodes"."tags") || ', ' || quote_literal("changed_nodes"."version") || ', ' || quote_literal("changed_nodes"."user_id") || ')'
      ) AS res))
  FROM (
  SELECT
    "pgs_current_node"."id",
    "pgs_current_node"."lat",
    "pgs_current_node"."lon",
    "pgs_current_node"."changeset_id",
    "pgs_current_node"."visible",
    "pgs_current_node"."timestamp",
    "pgs_current_node"."tags",
    "pgs_current_node"."version",
    "pgs_current_node"."user_id"
  FROM
    "pgs_current_node"
  WHERE
    "pgs_current_node"."id" IN (
      -- Get updated Ways
     SELECT
        "current_nodes"."id"
      FROM
        "current_nodes"
      WHERE
        "current_nodes"."changeset_id" = v_changeset_id
    ) ) "changed_nodes"
    INTO v_return_values;

    
-- Update Changed Ways in pgs
  SELECT
   array_agg((SELECT
    res
  FROM
    nps_dblink_pgs(
      'SELECT * FROM pgs_upsert_way(' || quote_literal("changed_ways"."id") || ', ' || quote_literal("changed_ways"."changeset_id") || ', ' || quote_literal("changed_ways"."visible") || ', ' || quote_literal("changed_ways"."timestamp") || ', ' || quote_literal("changed_ways"."nodes") || ', ' || quote_literal("changed_ways"."tags") || ', ' || quote_literal("changed_ways"."version") || ', ' || quote_literal("changed_ways"."user_id") || ')'
      ) AS res))
  FROM (
  SELECT
    "pgs_current_way"."id",
    "pgs_current_way"."version",
    "pgs_current_way"."visible",
    "pgs_current_way"."user_id",
    "pgs_current_way"."timestamp",
    "pgs_current_way"."changeset_id",
    "pgs_current_way"."tags",
    "pgs_current_way"."nodes"
  FROM
    "pgs_current_way"
  WHERE
    "pgs_current_way"."id" IN (
      -- Get updated Ways
     SELECT
        "current_ways"."id"
      FROM
        "current_ways"
      WHERE
        "current_ways"."changeset_id" = v_changeset_id
      UNION ALL
      -- Get ways that have nodes that have been changed
      SELECT
        "current_way_nodes"."way_id"
      FROM
        "current_nodes" JOIN "current_way_nodes" ON
          "current_nodes"."id" = "current_way_nodes"."node_id"
      WHERE
        "current_nodes"."changeset_id" = v_changeset_id
    ) ) "changed_ways"
    INTO v_return_values;

  
  -- Update Changed Relations
   SELECT
    array_agg((SELECT res FROM nps_dblink_pgs(
      'SELECT * FROM pgs_upsert_relation(' || quote_literal("pgs_current_relation"."id") || ', ' || quote_literal("pgs_current_relation"."changeset_id") || ', ' || quote_literal("pgs_current_relation"."visible") || ', ' || quote_literal("pgs_current_relation"."members") || ', ' || quote_literal("pgs_current_relation"."tags") || ', ' || quote_literal("pgs_current_relation"."timestamp") || ', '  || quote_literal("pgs_current_relation"."version") || ', ' || quote_literal("pgs_current_relation"."user_id") || ')'
    ) as res))
  FROM "pgs_current_relation" WHERE "pgs_current_relation"."id" IN 
  (
    SELECT
      "current_relation_members"."relation_id"
    FROM
      "nodes" JOIN "current_relation_members" ON
        "nodes"."node_id" = "current_relation_members"."member_id"
    WHERE
      lower("current_relation_members"."member_type"::text) = 'node' AND
      "nodes"."changeset_id" = v_changeset_id
    UNION ALL 
    SELECT
      "current_relation_members"."relation_id"
    FROM
      "current_ways" JOIN "current_relation_members" ON
        "current_ways"."id" = "current_relation_members"."member_id"
    WHERE
      lower("current_relation_members"."member_type"::text) = 'way' AND
      "current_ways"."changeset_id" = v_changeset_id
    UNION ALL
    SELECT
      "current_relation_members"."relation_id"
    FROM
      "current_nodes" JOIN "current_way_nodes" ON 
        "current_nodes"."id" = "current_way_nodes"."node_id" JOIN "current_relation_members" ON
        "current_relation_members"."member_id" = "current_way_nodes"."way_id"
    WHERE 
      "current_nodes"."changeset_id" = v_changeset_id AND
      lower("current_relation_members"."member_type"::text) = 'way'
  )
  INTO v_return_values;

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
