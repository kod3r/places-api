/*CREATE OR REPLACE FUNCTION public.nps_node_o2p_calculate_zorder(hstore)
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
*/
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
-- Convert JSON to hstore
CREATE OR REPLACE FUNCTION public.json_to_hstore(
  json
)
  RETURNS hstore AS $json_to_hstore$
DECLARE
  v_json ALIAS for $1;
  v_hstore HSTORE;
BEGIN
SELECT
  hstore(array_agg(keys), array_agg(vals))
FROM
(
SELECT 
  json_object_keys(v_json) keys,
  tags->>json_object_keys(v_json) vals
) get_vals
  v_hstore;

 RETURN v_hstore;
END;
$json_to_hstore$
LANGUAGE plpgsql;
  
-- DROP FUNCTION o2p_get_name(hstore, character(1));
CREATE OR REPLACE FUNCTION public.o2p_get_name(
  hstore,
  character(1)
)
  RETURNS text AS $o2p_get_name$
DECLARE
  v_hstore ALIAS for $1;
  v_member_type ALIAS FOR $2; -- Current not used, update this!
  v_name TEXT;
BEGIN

SELECT
  name
FROM (
  SELECT
    name,
    max(hstore_len) hstore_len,
    count(*) match_count
  FROM (
    SELECT
      name,
      available_tags,
      each(v_hstore) input_tags,
      hstore_len
    FROM (
      SELECT
        name,
        each(tags) available_tags,
        hstore_len
      FROM (
        SELECT
          name, 
          delete(json_to_hstore(tags), 'nps:fcat') tags,
          array_length(%% (delete(json_to_hstore(tags), 'nps:fcat')),1)/2 hstore_len
        FROM
          tag_list
        WHERE
          tag_list.geometry @> ARRAY['point'] AND
          tag_list.searchable is null or tag_list.searchable is true
      ) available_tags
    ) explode_tags
  ) paired_tags
  WHERE
    available_tags = input_tags
  GROUP BY name
  ) counted_tags
WHERE
  hstore_len = match_count
ORDER BY
  match_count DESC
LIMIT
  1
INTO
  v_name;

 RETURN v_name;
END;
$o2p_get_name$
LANGUAGE plpgsql;
