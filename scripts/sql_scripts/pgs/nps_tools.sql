CREATE OR REPLACE FUNCTION public.nps_node_o2p_calculate_zorder(hstore)
  RETURNS integer AS
$BODY$
DECLARE
  v_tags ALIAS for $1;
  v_zorder integer;
BEGIN

SELECT
  SUM(calc.order) as z_order
FROM
 (SELECT
  key,
  value,
  CASE
    WHEN key = 'nps:fcat' AND value = 'Visitor Center' THEN 40
    WHEN key = 'nps:fcat' AND value = 'Ranger Station' THEN 38
    WHEN key = 'nps:fcat' AND value = 'Information' THEN 36
    WHEN key = 'nps:fcat' AND value = 'Lodge' THEN 34
    WHEN key = 'nps:fcat' AND value = 'Campground' THEN 32
    WHEN key = 'nps:fcat' AND value = 'Food Service' THEN 30
    WHEN key = 'nps:fcat' AND value = 'Store' THEN 28
    WHEN key = 'nps:fcat' AND value = 'Picnic Area' THEN 26
    WHEN key = 'nps:fcat' AND value = 'Trailhead' THEN 24
    WHEN key = 'nps:fcat' AND value = 'Parking' THEN 22
    WHEN key = 'nps:fcat' AND value = 'Restroom' THEN 20
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
ALTER FUNCTION public.nps_node_o2p_calculate_zorder(hstore)
  OWNER TO postgres;
  
  ------------


CREATE OR REPLACE VIEW public.nps_planet_osm_point_view AS 
 SELECT nodes.id AS osm_id,
    nodes.tags -> 'nps:fcat'::text AS "FCategory",
    nodes.tags -> 'name'::text AS "name",
    tags AS "tags",
    nps_node_o2p_calculate_zorder(nodes.tags) AS z_order,
    NOW()::timestamp without time zone AS time,
    st_transform(nodes.geom, 900913) AS way
   FROM nodes
  WHERE nodes.tags <> ''::hstore AND 
  nodes.tags IS NOT NULL;

ALTER TABLE public.nps_planet_osm_point_view
  OWNER TO postgres;
  
  
  -----
  
-- DROP FUNCTION nps_pgs_update_o2p(bigint, character(1));
CREATE OR REPLACE FUNCTION nps_pgs_update_o2p(
  bigint,
  character(1)
) RETURNS boolean AS $nps_pgs_update_o2p$
  DECLARE
    v_id ALIAS FOR $1;
    v_member_type ALIAS FOR $2;
    v_rel_id BIGINT;
  BEGIN
    -- Update this object in the nps o2p tables
        IF v_member_type = 'N' THEN
          DELETE FROM planet_osm_point WHERE osm_id = v_id;
          INSERT INTO planet_osm_point (
            SELECT * FROM nps_planet_osm_point_view where osm_id = v_id
          );
    END IF;

  RETURN true;
  END;
$nps_pgs_update_o2p$ LANGUAGE plpgsql;


-- View: public.nps_planet_osm_point_view

-- DROP VIEW public.nps_planet_osm_point_view;

CREATE OR REPLACE VIEW public.nps_planet_osm_point_view AS 
 SELECT nodes.id AS osm_id,
    nodes.tags -> 'nps:fcat'::text AS "FCategory",
    nodes.tags -> 'name'::text AS name,
    nodes.tags,
    nps_node_o2p_calculate_zorder(nodes.tags) AS z_order,
    st_transform(nodes.geom, 900913) AS way,
    now()::timestamp without time zone AS created
   FROM nodes
  WHERE nodes.tags <> ''::hstore AND nodes.tags IS NOT NULL;

ALTER TABLE public.nps_planet_osm_point_view
  OWNER TO postgres;

-- Get the name using the tag database
 CREATE OR REPLACE FUNCTION public.o2p_get_name(
  bigint,
  character(1)
)
  RETURNS text AS $o2p_get_name$
DECLARE
  v_id ALIAS for $1;
  v_member_type ALIAS FOR $2; -- Current not used, update this!
  v_name TEXT;
BEGIN

SELECT
  name 
FROM (
  SELECT
    name, 
    Count(*), 
    (
      SELECT
        Count(*) 
       FROM (
         SELECT
           Json_each(tags) 
         FROM
           tag_list 
         WHERE
           tag_list.name = joined_tags.name
       ) internal_count_tags
    ) internal_count 
  FROM (
    SELECT
      tag_list_tags.*, 
      node_tags.* 
    FROM (
      SELECT
        name,
        Json_each(tags) each_tag,
        geometry,
        searchable
      FROM
        tag_list
    ) tag_list_tags JOIN (
      SELECT
        id,
        Json_each(tags :: json) each_tag 
      FROM
        nodes
    ) node_tags ON tag_list_tags.each_tag :: text = node_tags.each_tag :: text 
    WHERE
      tag_list_tags.geometry @> ARRAY['point'] AND
      (tag_list_tags.searchable is null or tag_list_tags.searchable is true) AND
      node_tags.id = v_id
   ) joined_tags 
GROUP BY
  joined_tags.name) counted_tags
WHERE
  counted_tags.count = counted_tags.internal_count
INTO
 v_name;

 RETURN v_name;
END;
$o2p_get_name$
LANGUAGE plpgsql;
