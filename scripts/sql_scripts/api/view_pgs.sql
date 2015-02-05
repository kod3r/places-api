CREATE OR REPLACE VIEW pgs_current_node AS
-- Subqueries run much faster than joins for this
SELECT
  "current_nodes"."id" AS "id",
  "current_nodes"."latitude"::float / 10000000 AS "lat",
  "current_nodes"."longitude"::float / 10000000 AS "lon",
  "current_nodes"."changeset_id",
  "current_nodes"."visible",
  "current_nodes"."timestamp",
  ( SELECT json_agg("result")
    FROM (
      SELECT "current_node_tags"."k", "current_node_tags"."v"
      FROM "current_node_tags"
      WHERE "current_node_tags"."node_id" = "current_nodes"."id"
    ) "result"
  ) AS "tags",
  "current_nodes"."version",
  (SELECT "changesets"."user_id" FROM "changesets" WHERE "changesets"."id" = "current_nodes"."changeset_id")
FROM
  "current_nodes";

CREATE OR REPLACE VIEW pgs_current_way AS
-- Subqueries run much faster than joins for this
SELECT
  "current_ways"."id",
  "current_ways"."version",
  "current_ways"."visible",
  ( SELECT "changesets"."user_id" 
    FROM "changesets" 
    WHERE "changesets"."id" = "current_ways"."changeset_id"
  ) AS "user_id",
  "current_ways"."timestamp",
  "current_ways"."changeset_id", 
  ( SELECT json_agg("result")
    FROM (
      SELECT "current_way_tags"."k", "current_way_tags"."v"
      FROM "current_way_tags"
      WHERE "current_way_tags"."way_id" = "current_ways"."id"
    ) "result"
  ) AS "tags",
  ( SELECT json_agg("nodes_in_way")
    FROM (
      SELECT "current_way_nodes"."node_id", "current_way_nodes"."sequence_id"
      FROM "current_way_nodes"
      WHERE "current_way_nodes"."way_id" = "current_ways"."id"
      ORDER BY "current_way_nodes"."sequence_id"
    ) "nodes_in_way"
  ) AS "nodes"
FROM
  "current_ways";
  
CREATE OR REPLACE VIEW pgs_current_relation AS
-- Subqueries run much faster than joins for this
SELECT
  "current_relations"."id",
  "current_relations"."version",
  "current_relations"."visible",
  ( SELECT "changesets"."user_id" 
    FROM "changesets" 
    WHERE "changesets"."id" = "current_relations"."changeset_id"
  ) AS "user_id",
  "current_relations"."timestamp",
  "current_relations"."changeset_id", 
  ( SELECT json_agg("result")
    FROM (
      SELECT "current_relation_tags"."k", "current_relation_tags"."v"
      FROM "current_relation_tags"
      WHERE "current_relation_tags"."relation_id" = "current_relations"."id"
    ) "result"
  ) AS "tags",
  ( SELECT json_agg("nodes_in_relation")
    FROM (
      SELECT
        "current_relation_members"."member_id",
        "current_relation_members"."member_type",
        "current_relation_members"."member_role",
        "current_relation_members"."sequence_id"
      FROM "current_relation_members"
      WHERE "current_relation_members"."relation_id" = "current_relations"."id"
      ORDER BY "current_relation_members"."sequence_id"
    ) "nodes_in_relation"
  ) AS "nodes"
FROM
  "current_relations";
