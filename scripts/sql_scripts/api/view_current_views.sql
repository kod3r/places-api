DROP TABLE IF EXISTS current_nodes CASCADE;
DROP VIEW IF EXISTS current_nodes;
CREATE VIEW current_nodes AS
SELECT
 nodes.node_id as id,
 nodes.latitude,
 nodes.longitude,
 nodes.changeset_id,
 nodes.visible,
 nodes."timestamp",
 nodes.tile,
 nodes.version
FROM
  nodes JOIN (
    SELECT
      node_id,
      MAX(version) as version
    FROM
      nodes
    GROUP BY
      node_id
  ) current
  ON
    current.node_id = nodes.node_id AND
    current.version = nodes.version;

DROP TABLE IF EXISTS current_node_tags CASCADE;
DROP VIEW IF EXISTS current_node_tags;
CREATE VIEW current_node_tags AS
SELECT
 node_tags.node_id,
 node_tags.version,
 node_tags.k,
 node_tags.v
FROM
  node_tags JOIN (
    SELECT
      node_id,
      MAX(version) as version
    FROM
      node_tags
    GROUP BY
      node_id
  ) current
  ON
    current.node_id = node_tags.node_id AND
    current.version = node_tags.version;

DROP TABLE IF EXISTS current_relation_members CASCADE;
DROP VIEW IF EXISTS current_relation_members;
CREATE VIEW current_relation_members AS
SELECT
 relation_members.relation_id,
 relation_members.member_type,
 relation_members.member_id,
 relation_members.member_role,
 relation_members.sequence_id
FROM
  relation_members JOIN (
    SELECT
      relation_id,
      MAX(version) as version
    FROM
      relation_members
    GROUP BY
      relation_id
  ) current
  ON
    current.relation_id = relation_members.relation_id AND
    current.version = relation_members.version;

DROP TABLE IF EXISTS current_relation_tags CASCADE;
DROP VIEW IF EXISTS current_relation_tags;
CREATE VIEW current_relation_tags AS
SELECT
 relation_tags.relation_id,
 relation_tags.k,
 relation_tags.v
FROM
  relation_tags JOIN (
    SELECT
      relation_id,
      MAX(version) as version
    FROM
      relation_tags
    GROUP BY
      relation_id
  ) current
  ON
    current.relation_id = relation_tags.relation_id AND
    current.version = relation_tags.version;

DROP TABLE IF EXISTS current_relations CASCADE;
DROP VIEW IF EXISTS current_relations;
CREATE VIEW current_relations AS
SELECT
 relations.relation_id as id,
 relations.changeset_id,
 relations."timestamp",
 relations.visible,
 relations.version
FROM
  relations JOIN (
    SELECT
      relation_id,
      MAX(version) as version
    FROM
      relations
    GROUP BY
      relation_id
  ) current
  ON
    current.relation_id = relations.relation_id AND
    current.version = relations.version;

DROP TABLE IF EXISTS current_way_nodes CASCADE;
DROP VIEW IF EXISTS current_way_nodes;
CREATE VIEW current_way_nodes AS
SELECT
 way_nodes.way_id,
 way_nodes.node_id,
 way_nodes.sequence_id
FROM
  way_nodes JOIN (
    SELECT
      way_id,
      MAX(version) as version
    FROM
      way_nodes
    GROUP BY
      way_id
  ) current
  ON
    current.way_id = way_nodes.way_id AND
    current.version = way_nodes.version;

DROP TABLE IF EXISTS current_way_tags CASCADE;
DROP VIEW IF EXISTS current_way_tags;
CREATE VIEW current_way_tags AS
SELECT
 way_tags.way_id,
 way_tags.k,
 way_tags.v
FROM
  way_tags JOIN (
    SELECT
      way_id,
      MAX(version) as version
    FROM
      way_tags
    GROUP BY
      way_id
  ) current
  ON
    current.way_id = way_tags.way_id AND
    current.version = way_tags.version;

DROP TABLE IF EXISTS current_ways CASCADE;
DROP VIEW IF EXISTS current_ways;
CREATE VIEW current_ways AS
SELECT
 ways.way_id as id,
 ways.changeset_id,
 ways."timestamp",
 ways.visible,
 ways.version
FROM
  ways JOIN (
    SELECT
      way_id,
      MAX(version) as version
    FROM
      ways
    GROUP BY
      way_id
  ) current
  ON
    current.way_id = ways.way_id AND
    current.version = ways.version;
