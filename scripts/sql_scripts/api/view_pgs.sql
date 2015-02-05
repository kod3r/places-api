CREATE VIEW pgs_current_way AS
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
