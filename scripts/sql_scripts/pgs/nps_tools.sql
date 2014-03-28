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
            SELECT * FROM planet_osm_point_view where osm_id = v_id
          );
    END IF;

  RETURN true;
  END;
$nps_pgs_update_o2p$ LANGUAGE plpgsql;
