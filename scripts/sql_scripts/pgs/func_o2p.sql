-- These are functions that mimic the functionality of osm2pgsql
-- http://wiki.openstreetmap.org/wiki/Osm2pgsql

-- Function: public.o2p_aggregate_line_relation(bigint)

-- DROP FUNCTION public.o2p_aggregate_line_relation(bigint);

CREATE OR REPLACE FUNCTION public.o2p_aggregate_line_relation(bigint)
  RETURNS geometry[] AS
$BODY$
DECLARE
  v_rel_id ALIAS for $1;
  v_way geometry[];
BEGIN

SELECT
  geom as route
FROM
  o2p_aggregate_relation(2301099)
  INTO
    v_way;

 RETURN v_way;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.o2p_aggregate_line_relation(bigint)
  OWNER TO postgres;


-- Function: public.o2p_aggregate_polygon_relation(bigint)

-- DROP FUNCTION public.o2p_aggregate_polygon_relation(bigint);

CREATE OR REPLACE FUNCTION public.o2p_aggregate_polygon_relation(bigint)
  RETURNS geometry[] AS
$BODY$
DECLARE
  v_rel_id ALIAS for $1;
  v_polygons geometry[];
BEGIN

SELECT
  array_agg(polygon) polygons
FROM (
  SELECT
    ST_ForceRHR(CASE
      WHEN holes[1] IS NULL THEN st_makepolygon(shell)
      ELSE st_makepolygon(shell, holes)
    END) polygon
  FROM (
    SELECT
      outside.line AS shell,
      array_agg(inside.line) AS holes
    FROM (
      SELECT
        geom as line,
        role
      FROM
        (SELECT unnest(geom) as geom, unnest(role) as role from o2p_aggregate_relation(v_rel_id)) out_sub
      WHERE
        role != 'inner' AND
        ST_IsClosed(geom)
    ) outside LEFT OUTER JOIN (
      SELECT
        geom as line,
        role
      FROM
        (SELECT unnest(geom) as geom, unnest(role) as role from o2p_aggregate_relation(v_rel_id)) in_sub
      WHERE
        role = 'inner' AND
        ST_IsClosed(geom)
    ) inside ON ST_CONTAINS(st_makepolygon(outside.line), inside.line)
  GROUP BY
    outside.line) polys
) poly_array
INTO
  v_polygons;


RETURN v_polygons;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.o2p_aggregate_polygon_relation(bigint)
  OWNER TO postgres;


-- Function: public.o2p_aggregate_relation(bigint)

-- DROP FUNCTION public.o2p_aggregate_relation(bigint);

CREATE OR REPLACE FUNCTION public.o2p_aggregate_relation(bigint)
  RETURNS aggregate_way AS
$BODY$
DECLARE
  v_rel_id ALIAS for $1;
  v_way geometry[];
  v_role text[];
BEGIN

SELECT
  array_agg(route),
  array_agg(member_role)
FROM (
  SELECT
    CASE
      WHEN direction = 'R' THEN st_reverse(st_makeline(st_reverse(way_geom)))
      ELSE st_makeline(way_geom)
    END route,
    member_role
  FROM (
    SELECT
      CASE
        WHEN new_line = true THEN
    CASE
      WHEN direction = 'N' THEN new_line_rank || sequence_id::text
      WHEN lead(new_line,1) OVER rw_seq = false THEN lead(new_line_rank,1) OVER rw_seq || direction
      ELSE new_line_rank || direction
    END
        ELSE new_line_rank || direction
      END grp,
      member_role,
      sequence_id,
      direction,
      way_geom
    FROM (
      SELECT
        way_geom,
        sequence_id,
        direction,
        new_line,
        member_role,
        sequence_id - rank() OVER (PARTITION BY new_line ORDER BY sequence_id) + 1 as new_line_rank
      FROM (
        SELECT
          sequence_id,
          member_role,
          CASE
            WHEN
              first_node = last_node
            THEN 'N'
            WHEN
              first_node = lag(last_node,1) OVER wr_seq OR
              last_node = lead(first_node,1) OVER wr_seq OR
              last_node = lag(last_node) OVER wr_seq
            THEN 'F'
            WHEN
              last_node = lag(first_node,1) OVER wr_seq OR
              first_node = lead(last_node,1) OVER wr_seq OR
              first_node = lag(first_node) OVER wr_seq
            THEN 'R'
            ELSE 'N'
          END as direction,
          CASE
            WHEN
              first_node = last_node THEN true
            WHEN
              first_node = lag(last_node,1) OVER wr_seq OR
              last_node = lag(first_node,1) OVER wr_seq OR
              first_node = lag(first_node) OVER wr_seq OR
              last_node = lag(last_node) OVER wr_seq
            THEN false
            ELSE true
          END as new_line,
          CASE
            WHEN
              first_node = lag(first_node) OVER wr_seq OR
              last_node = lag(last_node) OVER wr_seq
            THEN st_reverse(way_geom)
            ELSE way_geom
          END as way_geom
          FROM (
            SELECT
              ways.nodes[1] first_node,
              ways.nodes[array_length(ways.nodes, 1)] last_node,
              o2p_calculate_nodes_to_line(ways.nodes) as way_geom,
              member_role,
              sequence_id
            FROM
            relation_members JOIN
                ways ON ways.id = relation_members.member_id
              WHERE
                relation_id = v_rel_id AND -- relation: 2301099 is rt 13 (for testing)
                member_type = 'W'
              ORDER BY
                sequence_id
          ) way_rels
          WINDOW wr_seq as (
           ORDER BY way_rels.sequence_id
          )
      ) directioned_ways ORDER BY directioned_ways.sequence_id 
    ) ranked_ways
     WINDOW rw_seq as (
      ORDER BY ranked_ways.sequence_id
    )
    ORDER BY
      ranked_ways.sequence_id
  ) grouped_ways GROUP BY
    grp,
    direction,
    member_role
  ORDER BY
    min(sequence_id)
 ) ways_agg
  INTO
    v_way, v_role;

 RETURN (v_way, v_role);
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.o2p_aggregate_relation(bigint)
  OWNER TO postgres;


-- Function: public.o2p_calculate_nodes_to_line(bigint[])

-- DROP FUNCTION public.o2p_calculate_nodes_to_line(bigint[]);

CREATE OR REPLACE FUNCTION public.o2p_calculate_nodes_to_line(bigint[])
  RETURNS geometry AS
$BODY$
DECLARE
  v_nodes ALIAS for $1;
  v_line geometry;
BEGIN
-- looks up all the nodes and creates a linestring from them
SELECT
  ST_MakeLine(g.geom)
FROM (
  SELECT
    geom
  FROM
    nodes
    JOIN (
      SELECT 
        unnest(v_nodes) as node
    ) way ON nodes.id = way.node
) g
INTO
  v_line;

-- If it's a closed line, make it into a polygon
-- it also must have 4 points?
--IF v_nodes[1] = v_nodes[array_length(v_nodes, 1)] THEN
--  SELECT ST_MakePolygon(v_line) INTO v_line;
--END IF;

RETURN v_line;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.o2p_calculate_nodes_to_line(bigint[])
  OWNER TO postgres;

-- Function: public.o2p_calculate_zorder(hstore)

-- DROP FUNCTION public.o2p_calculate_zorder(hstore);

CREATE OR REPLACE FUNCTION public.o2p_calculate_zorder(hstore)
  RETURNS integer AS
$BODY$
DECLARE
  v_tags ALIAS for $1;
  v_zorder integer;
BEGIN
  -- https://github.com/openstreetmap/osm2pgsql/blob/master/style.lua

SELECT
  SUM(calc.order) as z_order
FROM
 (SELECT
  key,
  value,
  CASE
    WHEN key = 'railway' THEN 5
    WHEN key = 'boundary' AND value = 'administrative' THEN 0
    WHEN key = 'bridge' AND value = 'yes' THEN 10
    WHEN key = 'bridge' AND value = 'true' THEN 10
    WHEN key = 'bridge' AND value = '1' THEN 10
    WHEN key = 'tunnel' AND value = 'yes' THEN -10
    WHEN key = 'tunnel' AND value = 'true' THEN -10
    WHEN key = 'tunnel' AND value = '1' THEN -10
    WHEN key = 'highway' AND value = 'minor' THEN 3
    WHEN key = 'highway' AND value = 'road' THEN 3
    WHEN key = 'highway' AND value = 'unclassified' THEN 3
    WHEN key = 'highway' AND value = 'residential' THEN 3
    WHEN key = 'highway' AND value = 'tertiary_link' THEN 4
    WHEN key = 'highway' AND value = 'tertiary' THEN 4
    WHEN key = 'highway' AND value = 'secondary_link' THEN 6
    WHEN key = 'highway' AND value = 'secondary' THEN 6
    WHEN key = 'highway' AND value = 'primary_link' THEN 7
    WHEN key = 'highway' AND value = 'primary' THEN 7
    WHEN key = 'highway' AND value = 'trunk_link' THEN 8
    WHEN key = 'highway' AND value = 'trunk' THEN 8
    WHEN key = 'highway' AND value = 'motorway_link' THEN 9
    WHEN key = 'highway' AND value = 'motorway' THEN 9
    WHEN key = 'layer' THEN 10 * value::integer
    ELSE 0
  END as order
FROM
  each(v_tags)) calc
INTO
  v_zorder;

RETURN v_zorder;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.o2p_calculate_zorder(hstore)
  OWNER TO postgres;


-- Function: public.o2p_osm_grid(geometry, integer, integer)

-- DROP FUNCTION public.o2p_osm_grid(geometry, integer, integer);

CREATE OR REPLACE FUNCTION public.o2p_osm_grid(geometry, integer, integer)
  RETURNS SETOF text[] AS
$BODY$
  DECLARE
    v_in_bbox ALIAS FOR $1;
    v_width ALIAS FOR $2;
    v_height ALIAS FOR $3;
    v_bbox geometry;
    v_xmax float; v_xmin float; v_ymax float; v_ymin float;
    v_grid text array;
  BEGIN
    select ST_transform(v_in_bbox, 900913) into v_bbox;
    select st_xmax(v_bbox) into v_xmax;
    select st_xmin(v_bbox) into v_xmin;
    select st_ymax(v_bbox) into v_ymax;
    select st_ymin(v_bbox) into v_ymin;
for v_grid in 
WITH bbox_geoms AS (
SELECT * FROM (
SELECT osm_id, name, highway, z_order, way, 'line' as datatype
FROM planet_osm_line
UNION
SELECT osm_id, name, highway, z_order, way, 'polygon' as datatype
FROM planet_osm_polygon
UNION
SELECT osm_id, name, highway, z_order * 2 as "z_order", way, 'point' as datatype
FROM planet_osm_point
) g WHERE way && v_bbox and st_intersects(way, v_bbox))
SELECT row FROM (SELECT (
SELECT
  array_agg((select 
    osm_id
   from
    bbox_geoms
   where
    way && ST_MakeEnvelope(
    v_xmin + (((v_xmax - v_xmin)/v_width::float) * a)::float,
    v_ymax - (((v_ymax - v_ymin)/v_height::float) * b)::float,
    v_xmin + (((v_xmax - v_xmin)/v_width::float) * (a+1))::float,
    v_ymax - (((v_ymax - v_ymin)/v_height::float) * (b+1))::float,
    900913) AND ST_intersects(way, ST_MakeEnvelope(
    v_xmin + (((v_xmax - v_xmin)/v_width::float) * a)::float,
    v_ymax - (((v_ymax - v_ymin)/v_height::float) * b)::float,
    v_xmin + (((v_xmax - v_xmin)/v_width::float) * (a+1))::float,
    v_ymax - (((v_ymax - v_ymin)/v_height::float) * (b+1))::float,
    900913))
   and
    osm_id is not null
   order by
    z_order desc
   limit 1))
 FROM
 generate_series(0,v_width-1) a) as "row"
FROM
 generate_series(0,v_height-1) b order by b) h
loop
return next v_grid;
end loop;

 --RETURN NEXT v_grid;
 END;
 $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.o2p_osm_grid(geometry, integer, integer)
  OWNER TO postgres;
  
  
--------------

DROP FUNCTION pgs_update_o2p(bigint, character(1));
CREATE OR REPLACE FUNCTION pgs_update_o2p(
  bigint,
  character(1)
) RETURNS boolean AS $pgs_update_o2p$
  DECLARE
    v_id ALIAS FOR $1;
    v_member_type ALIAS FOR $2;
    v_rel_id BIGINT;
  BEGIN
    -- Update this object in the o2p tables
    -- A loop functions quicker than a join query from the view

    IF v_member_type = 'R' THEN
      DELETE FROM planet_osm_line WHERE osm_id = v_id * -1;
      DELETE FROM planet_osm_roads WHERE osm_id = v_id * -1;
      DELETE FROM planet_osm_polygon WHERE osm_id = v_id * -1;
      INSERT INTO planet_osm_line (
        SELECT * FROM planet_osm_line_view where osm_id = v_id * -1
      );
      INSERT INTO planet_osm_roads (
        SELECT * FROM planet_osm_roads_view where osm_id = v_id * -1
      );
      INSERT INTO planet_osm_polygon (
        SELECT * FROM planet_osm_polygon_view where osm_id = v_id * -1
      );
    ELSE
      FOR v_rel_id IN
        SELECT
          DISTINCT(relation_id) * -1 AS rel_id
        FROM
          relation_members
        WHERE
          member_type = v_member_type AND
          member_id = v_id
        UNION
          SELECT v_id
      LOOP
        IF v_member_type = 'N' THEN
          DELETE FROM planet_osm_point WHERE osm_id = v_rel_id;
          INSERT INTO planet_osm_point (
            SELECT * FROM planet_osm_point_view where osm_id = v_rel_id
          );
        ELSIF v_member_type = 'W' THEN
          DELETE FROM planet_osm_line WHERE osm_id = v_rel_id;
          DELETE FROM planet_osm_roads WHERE osm_id = v_rel_id;
          DELETE FROM planet_osm_polygon WHERE osm_id = v_rel_id;
          INSERT INTO planet_osm_line (
            SELECT * FROM planet_osm_line_view where osm_id = v_rel_id
          );
          INSERT INTO planet_osm_roads (
            SELECT * FROM planet_osm_roads_view where osm_id = v_rel_id
          );
          INSERT INTO planet_osm_polygon (
            SELECT * FROM planet_osm_polygon_view where osm_id = v_rel_id
          );
        END IF;
      END LOOP;
    END IF;

  RETURN true;
  END;
$pgs_update_o2p$ LANGUAGE plpgsql;
