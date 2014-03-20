-- View: current_node_tags

-- DROP VIEW current_node_tags;

CREATE OR REPLACE VIEW current_node_tags AS 
 SELECT node_tags.node_id,
    node_tags.version,
    node_tags.k,
    node_tags.v
   FROM node_tags
   JOIN ( SELECT node_tags_1.node_id,
            max(node_tags_1.version) AS version
           FROM node_tags node_tags_1
          GROUP BY node_tags_1.node_id) current ON current.node_id = node_tags.node_id AND current.version = node_tags.version;

ALTER TABLE current_node_tags
  OWNER TO postgres;


-- View: current_nodes

-- DROP VIEW current_nodes;

CREATE OR REPLACE VIEW current_nodes AS 
 SELECT nodes.node_id AS id,
    nodes.latitude,
    nodes.longitude,
    nodes.changeset_id,
    nodes.visible,
    nodes."timestamp",
    nodes.tile,
    nodes.version
   FROM nodes
   JOIN ( SELECT nodes_1.node_id,
            max(nodes_1.version) AS version
           FROM nodes nodes_1
          GROUP BY nodes_1.node_id) current ON current.node_id = nodes.node_id AND current.version = nodes.version;

ALTER TABLE current_nodes
  OWNER TO postgres;


-- View: current_relation_members

-- DROP VIEW current_relation_members;

CREATE OR REPLACE VIEW current_relation_members AS 
 SELECT relation_members.relation_id,
    relation_members.member_type,
    relation_members.member_id,
    relation_members.member_role,
    relation_members.sequence_id
   FROM relation_members
   JOIN ( SELECT relation_members_1.relation_id,
            max(relation_members_1.version) AS version
           FROM relation_members relation_members_1
          GROUP BY relation_members_1.relation_id) current ON current.relation_id = relation_members.relation_id AND current.version = relation_members.version;

ALTER TABLE current_relation_members
  OWNER TO postgres;


-- View: current_relation_tags

-- DROP VIEW current_relation_tags;

CREATE OR REPLACE VIEW current_relation_tags AS 
 SELECT relation_tags.relation_id,
    relation_tags.k,
    relation_tags.v
   FROM relation_tags
   JOIN ( SELECT relation_tags_1.relation_id,
            max(relation_tags_1.version) AS version
           FROM relation_tags relation_tags_1
          GROUP BY relation_tags_1.relation_id) current ON current.relation_id = relation_tags.relation_id AND current.version = relation_tags.version;

ALTER TABLE current_relation_tags
  OWNER TO postgres;


-- View: current_relations

-- DROP VIEW current_relations;

CREATE OR REPLACE VIEW current_relations AS 
 SELECT relations.relation_id AS id,
    relations.changeset_id,
    relations."timestamp",
    relations.visible,
    relations.version
   FROM relations
   JOIN ( SELECT relations_1.relation_id,
            max(relations_1.version) AS version
           FROM relations relations_1
          GROUP BY relations_1.relation_id) current ON current.relation_id = relations.relation_id AND current.version = relations.version;

ALTER TABLE current_relations
  OWNER TO postgres;


-- View: current_way_nodes

-- DROP VIEW current_way_nodes;

CREATE OR REPLACE VIEW current_way_nodes AS 
 SELECT way_nodes.way_id,
    way_nodes.node_id,
    way_nodes.sequence_id
   FROM way_nodes
   JOIN ( SELECT way_nodes_1.way_id,
            max(way_nodes_1.version) AS version
           FROM way_nodes way_nodes_1
          GROUP BY way_nodes_1.way_id) current ON current.way_id = way_nodes.way_id AND current.version = way_nodes.version;

ALTER TABLE current_way_nodes
  OWNER TO postgres;

-- View: current_way_tags

-- DROP VIEW current_way_tags;

CREATE OR REPLACE VIEW current_way_tags AS 
 SELECT way_tags.way_id,
    way_tags.k,
    way_tags.v
   FROM way_tags
   JOIN ( SELECT way_tags_1.way_id,
            max(way_tags_1.version) AS version
           FROM way_tags way_tags_1
          GROUP BY way_tags_1.way_id) current ON current.way_id = way_tags.way_id AND current.version = way_tags.version;

ALTER TABLE current_way_tags
  OWNER TO postgres;

-- View: current_ways

-- DROP VIEW current_ways;

CREATE OR REPLACE VIEW current_ways AS 
 SELECT ways.way_id AS id,
    ways.changeset_id,
    ways."timestamp",
    ways.visible,
    ways.version
   FROM ways
   JOIN ( SELECT ways_1.way_id,
            max(ways_1.version) AS version
           FROM ways ways_1
          GROUP BY ways_1.way_id) current ON current.way_id = ways.way_id AND current.version = ways.version;

ALTER TABLE current_ways
  OWNER TO postgres;
