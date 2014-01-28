-- These scripts are not to be run unless they are needed

-- Refresh all tables from views
-- This should be run to initially populate the o2p tables, and if the schemas are changed at all

DROP TABLE planet_osm_point;
CREATE TABLE planet_osm_point as (
    SELECT * FROM planet_osm_point_view
  );
CREATE INDEX planet_osm_point_idx
  ON public.planet_osm_point
  USING gist
  (way);

  
DROP TABLE planet_osm_line;
CREATE TABLE  planet_osm_line as (
    SELECT * FROM planet_osm_line_view
  );
CREATE INDEX planet_osm_line_idx
  ON public.planet_osm_line
  USING gist
  (way);
  
DROP TABLE  planet_osm_roads;
CREATE TABLE  planet_osm_roads as (
    SELECT * FROM planet_osm_roads_view
  );
CREATE INDEX planet_osm_roads_idx
  ON public.planet_osm_roads
  USING gist
  (way);
  
DROP TABLE planet_osm_polygon;
CREATE TABLE planet_osm_polygon as (
    SELECT * FROM planet_osm_polygon_view
  );
CREATE INDEX planet_osm_polygon_idx
  ON public.planet_osm_polygon
  USING gist
  (way);
