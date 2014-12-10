-- Views (not query functions)

-- Nodes
DROP VIEW IF EXISTS pgs_current_nodes;
CREATE VIEW pgs_current_nodes AS
SELECT
  nodes.id as "id",
  'true'::text as "visible",
  nodes.version as "version",
  nodes.changeset_id as "changeset",
  nodes.tstamp AT TIME ZONE 'UTC' as "timestamp",
  users.name as "user",
  nodes.user_id as "uid",
  ST_Y(nodes.geom) as "lat",
  ST_X(nodes.geom) as "lon",
  (SELECT json_agg(tg) FROM (SELECT skeys(nodes.tags) "k", svals(nodes.tags) "v") tg) as "tag"
FROM
  nodes
  JOIN users
    ON users.id = nodes.user_id;

-- Ways
DROP VIEW IF EXISTS pgs_current_ways;
CREATE VIEW pgs_current_ways AS
SELECT
  ways.id as "id",
  'true'::text as "visible",
  ways.version as "version",
  ways.changeset_id as "changeset",
  ways.tstamp AT TIME ZONE 'UTC' as "timestamp",
  users.name as "user",
  ways.user_id as "uid",
  (SELECT json_agg(nd) FROM (SELECT unnest(ways.nodes) "ref") as nd) as "nd",
  (SELECT json_agg(tg) FROM (SELECT skeys(ways.tags) "k", svals(ways.tags) "v") tg) as "tag"
FROM
  ways
  JOIN users
    ON users.id = ways.user_id;

-- Relations
DROP VIEW IF EXISTS pgs_current_relations;
CREATE VIEW pgs_current_relations AS
SELECT
  relations.id as "id",
  'true'::text as "visible",
  relations.version as "version",
  relations.changeset_id as "changeset",
  relations.tstamp AT TIME ZONE 'UTC' as "timestamp",
  users.name as "user",
  relations.user_id as "uid",
  (SELECT json_agg(members) FROM (
    SELECT
      CASE
        WHEN UPPER(member_type)='R' then 'relation'
        WHEN UPPER(member_type)='W' then 'way'
        WHEN UPPER(member_type)='N' then 'node'
        ELSE null
      END as "type",
      member_id as "ref",
      member_role as "role"
    FROM
      relation_members
        JOIN (SELECT relations.id id) this_relation
        ON relation_members.relation_id = this_relation.id
    ) members) as "member",
  (SELECT json_agg(tg) FROM (SELECT skeys(relations.tags) "k", svals(relations.tags) "v") tg) as "tag"
FROM
  relations
  JOIN users
    ON users.id = relations.user_id;

-- Type for map bbox return
DROP TYPE IF EXISTS osmMap CASCADE;
CREATE TYPE osmMap AS (bounds json, node json, way json, relation json, limits json);

-- Bbox function
CREATE OR REPLACE FUNCTION getBbox (numeric, numeric, numeric, numeric, numeric) RETURNS osmMap AS $getBbox$
  DECLARE
    v_minLat ALIAS FOR $1;
    v_minLon ALIAS FOR $2;
    v_maxLat ALIAS FOR $3;
    v_maxLon ALIAS FOR $4;
    v_node_limit ALIAS FOR $5;
    v_bounds json;
    v_nodes json;
    v_ways json;
    v_relations json;
    v_max_number_of_nodes bigint;
    v_limit_reached json;
  BEGIN
    v_max_number_of_nodes := v_node_limit;

    CREATE LOCAL TEMP TABLE nodes_in_bbox ON COMMIT DROP AS
    SELECT DISTINCT
      nodes.id as node_id
    FROM
      nodes
    WHERE
      nodes.geom && ST_MakeEnvelope(v_minLon, v_minLat, v_maxLon, v_maxLat, 4326)
    LIMIT
      v_max_number_of_nodes;

    IF (SELECT COUNT(*)<v_max_number_of_nodes FROM nodes_in_bbox) THEN

    CREATE LOCAL TEMP TABLE ways_in_bbox ON COMMIT DROP AS
    SELECT DISTINCT
      way_nodes.way_id AS way_id
    FROM
      nodes_in_bbox
    JOIN
      way_nodes ON nodes_in_bbox.node_id = way_nodes.node_id;

    CREATE LOCAL TEMP TABLE nodes_in_ways_in_bbox ON COMMIT DROP AS
    SELECT DISTINCT
      node_id
    FROM
      way_nodes
      JOIN ways_in_bbox
        ON way_nodes.way_id = ways_in_bbox.way_id;

    CREATE LOCAL TEMP TABLE nodes_in_query ON COMMIT DROP AS
    SELECT DISTINCT
      node_id
    FROM (
     SELECT node_id from nodes_in_ways_in_bbox
     UNION
     SELECT node_id from nodes_in_bbox
    ) nodes_in_query_union;

    SELECT
      to_json(bboxBounds)
    FROM
      (
      SELECT
        ST_YMin(extent.newGeom) as minLat,
        ST_XMin(extent.newGeom) as minLon,
        ST_YMax(extent.newGeom) as maxLat,
        ST_XMax(extent.newGeom) as maxLon
      FROM
        (
        SELECT
          ST_Extent(geom) AS newGeom
        FROM
          nodes_in_query
            JOIN nodes
            ON nodes_in_query.node_id = nodes.id
        ) extent
      ) bboxBounds INTO v_bounds;

    CREATE LOCAL TEMP TABLE relations_in_bbox ON COMMIT DROP AS
    SELECT DISTINCT
      relation_members.relation_id
    FROM
      relation_members
      JOIN ways_in_bbox
        ON ways_in_bbox.way_id = relation_members.member_id
        AND UPPER(relation_members.member_type) = 'W'
    UNION
      SELECT DISTINCT
        relation_members.relation_id
      FROM
        relation_members
        JOIN nodes_in_query
          ON nodes_in_query.node_id = relation_members.member_id
          and UPPER(relation_members.member_type) = 'N';

    SELECT json_agg(to_json(bboxNodes)) FROM (
    SELECT
      pgs_current_nodes.*
    FROM
      pgs_current_nodes
      JOIN nodes_in_query
        ON pgs_current_nodes.id = nodes_in_query.node_id
    ) bboxNodes
    INTO v_nodes;

    SELECT json_agg(to_json(bboxWays)) FROM (
    SELECT
      pgs_current_ways.*
    FROM
      pgs_current_ways
      JOIN ways_in_bbox
        ON pgs_current_ways.id = ways_in_bbox.way_id
    ) bboxWays
    INTO v_ways;

    SELECT json_agg(to_json(bboxRelations)) FROM (
    SELECT
      pgs_current_relations.*
    FROM
      pgs_current_relations
      JOIN relations_in_bbox
        ON pgs_current_relations.id = relations_in_bbox.relation_id
    ) bboxRelations
    INTO v_relations;
  END IF;

    SELECT json_agg(to_json(max_limit)) FROM (
    SELECT
      count(*) >= v_max_number_of_nodes AS reached,
      v_max_number_of_nodes as max,
      count(*) as nodes
    FROM
      nodes_in_bbox
    ) max_limit
    INTO
      v_limit_reached;

    RETURN (v_bounds, v_nodes, v_ways, v_relations, v_limit_reached);

  END;
$getBbox$ LANGUAGE plpgsql;

-- This should be a new file, maybe call it tables?
-- Table: public.planet_osm_line

-- DROP TABLE public.planet_osm_line;

CREATE TABLE public.planet_osm_line
(
  osm_id bigint,
  access text,
  "addr:housename" text,
  "addr:housenumber" text,
  "addr:interpolation" text,
  admin_level text,
  aerialway text,
  aeroway text,
  amenity text,
  area text,
  barrier text,
  bicycle text,
  brand text,
  bridge text,
  boundary text,
  building text,
  construction text,
  covered text,
  culvert text,
  cutting text,
  denomination text,
  disused text,
  embankment text,
  foot text,
  "generator:source" text,
  harbour text,
  highway text,
  historic text,
  horse text,
  intermittent text,
  junction text,
  landuse text,
  layer text,
  leisure text,
  lock text,
  man_made text,
  military text,
  motorcar text,
  name text,
  "natural" text,
  office text,
  oneway text,
  operator text,
  place text,
  population text,
  power text,
  power_source text,
  public_transport text,
  railway text,
  ref text,
  religion text,
  route text,
  service text,
  shop text,
  sport text,
  surface text,
  toll text,
  tourism text,
  "tower:type" text,
  tracktype text,
  tunnel text,
  water text,
  waterway text,
  wetland text,
  width text,
  wood text,
  z_order integer,
  way_area double precision,
  way geometry
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.planet_osm_line
  OWNER TO osm;

-- Index: public.planet_osm_line_idx

-- DROP INDEX public.planet_osm_line_idx;

CREATE INDEX planet_osm_line_idx
  ON public.planet_osm_line
  USING gist
  (way);

-- Table: public.planet_osm_point

-- DROP TABLE public.planet_osm_point;

CREATE TABLE public.planet_osm_point
(
  osm_id bigint,
  access text,
  "addr:housename" text,
  "addr:housenumber" text,
  "addr:interpolation" text,
  admin_level text,
  aerialway text,
  aeroway text,
  amenity text,
  area text,
  barrier text,
  bicycle text,
  brand text,
  bridge text,
  boundary text,
  building text,
  construction text,
  covered text,
  culvert text,
  cutting text,
  denomination text,
  disused text,
  embankment text,
  foot text,
  "generator:source" text,
  harbour text,
  highway text,
  historic text,
  horse text,
  intermittent text,
  junction text,
  landuse text,
  layer text,
  leisure text,
  lock text,
  man_made text,
  military text,
  motorcar text,
  name text,
  "natural" text,
  office text,
  oneway text,
  operator text,
  place text,
  population text,
  power text,
  power_source text,
  public_transport text,
  railway text,
  ref text,
  religion text,
  route text,
  service text,
  shop text,
  sport text,
  surface text,
  toll text,
  tourism text,
  "tower:type" text,
  tracktype text,
  tunnel text,
  water text,
  waterway text,
  wetland text,
  width text,
  wood text,
  z_order integer,
  way geometry
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.planet_osm_point
  OWNER TO osm;

-- Index: public.planet_osm_point_idx

-- DROP INDEX public.planet_osm_point_idx;

CREATE INDEX planet_osm_point_idx
  ON public.planet_osm_point
  USING gist
  (way);

-- Table: public.planet_osm_polygon

-- DROP TABLE public.planet_osm_polygon;

CREATE TABLE public.planet_osm_polygon
(
  osm_id bigint,
  access text,
  "addr:housename" text,
  "addr:housenumber" text,
  "addr:interpolation" text,
  admin_level text,
  aerialway text,
  aeroway text,
  amenity text,
  area text,
  barrier text,
  bicycle text,
  brand text,
  bridge text,
  boundary text,
  building text,
  construction text,
  covered text,
  culvert text,
  cutting text,
  denomination text,
  disused text,
  embankment text,
  foot text,
  "generator:source" text,
  harbour text,
  highway text,
  historic text,
  horse text,
  intermittent text,
  junction text,
  landuse text,
  layer text,
  leisure text,
  lock text,
  man_made text,
  military text,
  motorcar text,
  name text,
  "natural" text,
  office text,
  oneway text,
  operator text,
  place text,
  population text,
  power text,
  power_source text,
  public_transport text,
  railway text,
  ref text,
  religion text,
  route text,
  service text,
  shop text,
  sport text,
  surface text,
  toll text,
  tourism text,
  "tower:type" text,
  tracktype text,
  tunnel text,
  water text,
  waterway text,
  wetland text,
  width text,
  wood text,
  z_order integer,
  way_area double precision,
  way geometry
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.planet_osm_polygon
  OWNER TO osm;

-- Index: public.planet_osm_polygon_idx

-- DROP INDEX public.planet_osm_polygon_idx;

CREATE INDEX planet_osm_polygon_idx
  ON public.planet_osm_polygon
  USING gist
  (way);

-- Table: public.planet_osm_roads

-- DROP TABLE public.planet_osm_roads;

CREATE TABLE public.planet_osm_roads
(
  osm_id bigint,
  access text,
  "addr:housename" text,
  "addr:housenumber" text,
  "addr:interpolation" text,
  admin_level text,
  aerialway text,
  aeroway text,
  amenity text,
  area text,
  barrier text,
  bicycle text,
  brand text,
  bridge text,
  boundary text,
  building text,
  construction text,
  covered text,
  culvert text,
  cutting text,
  denomination text,
  disused text,
  embankment text,
  foot text,
  "generator:source" text,
  harbour text,
  highway text,
  historic text,
  horse text,
  intermittent text,
  junction text,
  landuse text,
  layer text,
  leisure text,
  lock text,
  man_made text,
  military text,
  motorcar text,
  name text,
  "natural" text,
  office text,
  oneway text,
  operator text,
  place text,
  population text,
  power text,
  power_source text,
  public_transport text,
  railway text,
  ref text,
  religion text,
  route text,
  service text,
  shop text,
  sport text,
  surface text,
  toll text,
  tourism text,
  "tower:type" text,
  tracktype text,
  tunnel text,
  water text,
  waterway text,
  wetland text,
  width text,
  wood text,
  z_order integer,
  way_area double precision,
  way geometry
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.planet_osm_roads
  OWNER TO osm;

-- Index: public.planet_osm_roads_idx

-- DROP INDEX public.planet_osm_roads_idx;

CREATE INDEX planet_osm_roads_idx
  ON public.planet_osm_roads
  USING gist
  (way);
