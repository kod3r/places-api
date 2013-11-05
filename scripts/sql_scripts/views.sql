-- VIEWS

-- Nodes
DROP VIEW IF EXISTS api_current_nodes;
CREATE VIEW api_current_nodes AS
SELECT
  current_nodes.id as id,
  current_nodes.visible,
  current_nodes.version,
  current_nodes.changeset_id as changeset,
  current_nodes.timestamp AT TIME ZONE 'UTC' as timestamp,
  users.display_name as user,
  changesets.user_id as uid,
  current_nodes.latitude/10000000::float as lat,
  current_nodes.longitude/10000000::float as lon,
  (SELECT json_agg(tags) from (SELECT k, v FROM node_tags WHERE node_id = current_nodes.id) tags) AS tag
FROM
  current_nodes
  JOIN changesets
    ON current_nodes.changeset_id = changesets.id
     JOIN users
       ON changesets.user_id = users.id;

-- Ways
DROP VIEW IF EXISTS api_current_ways;
CREATE VIEW api_current_ways AS
SELECT
  current_ways.id AS id,
  current_ways.visible AS visible,
  current_ways.version AS VERSION,
  current_ways.changeset_id AS changeset,
  current_ways.timestamp AT TIME ZONE 'UTC' AS TIMESTAMP,
  users.display_name AS USER,
  changesets.user_id AS uid,
  (SELECT json_agg(nodes) FROM (
    SELECT node_id AS ref
    FROM current_way_nodes
    WHERE current_way_nodes.way_id = current_ways.id
      AND version = current_ways.version
    ORDER BY sequence_id
    ) nodes
  ) AS nd,
  (SELECT json_agg(tags) FROM (
      SELECT k, v
      FROM current_way_tags
      WHERE current_way_tags.way_id = current_ways.id
    ) tags
  ) AS tag
FROM
  current_ways
  JOIN changesets
    ON current_ways.changeset_id = changesets.id
  JOIN users
    ON changesets.user_id = users.id;

-- Relations
DROP VIEW IF EXISTS api_current_relations;
CREATE VIEW api_current_relations AS
SELECT
  current_relations.id as id,
  current_relations.visible as visible,
  current_relations.version as version,
  current_relations.changeset_id as changeset,
  current_relations.timestamp AT TIME ZONE 'UTC' as timestamp,
  users.display_name as user,
  changesets.user_id as uid,
  (SELECT json_agg(members) FROM (
    SELECT
      lower(member_type::text) as type,
      member_id as ref, 
      member_role as role
    FROM
      relation_members 
    WHERE
      relation_id = current_relations.id
  ) members) as member,
  (SELECT json_agg(tags) FROM (
    SELECT
      k,
      v
    FROM
      current_relation_tags
    WHERE
      current_relation_tags.relation_id = current_relations.id
  ) tags) as tag
FROM
  current_relations
  JOIN changesets
    ON current_relations.changeset_id = changesets.id
    JOIN users
      ON changesets.user_id = users.id;
