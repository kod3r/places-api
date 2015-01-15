-----------------------------------------------------------------------
-- nps render tables

-- Table: public.nps_render_point

-- DROP TABLE public.nps_render_point;

CREATE TABLE public.nps_render_point
(
  osm_id bigint NOT NULL,
  version integer,
  name text,
  type text, -- This is a calculated field. It calculates the point "type" from its "tags" field. It uses the o2p_get_name function to perform the calculation.
  tags hstore, -- This contains all of the OpenStreetMap style tags associated with this point.
  rendered timestamp without time zone, -- This contains the time that this specific point was rendered. This is important for synchronizing the render tools.
  the_geom geometry, -- Contains the geometry for the point.
  z_order integer, -- Contains the display order of the points.  This is a calculated field, it is calclated from the "tags" field using the "nps_node_o2p_calculate_zorder" function.
  unit_code text, -- The unit code of the park that contains this point
  CONSTRAINT osm_id PRIMARY KEY (osm_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.nps_render_point
  OWNER TO osm;
COMMENT ON TABLE public.nps_render_point
  IS 'This table contains the most recent version of all visible points in order to be displayed on park tiles as well as be used in CartoDB.
In the future (as on jan 2015) this table will only contain the points that have been fully validated';
COMMENT ON COLUMN public.nps_render_point.type IS 'This is a calculated field. It calculates the point "type" from its "tags" field. It uses the o2p_get_name function to perform the calculation.';
COMMENT ON COLUMN public.nps_render_point.tags IS 'This contains all of the OpenStreetMap style tags associated with this point.';
COMMENT ON COLUMN public.nps_render_point.rendered IS 'This contains the time that this specific point was rendered. This is important for synchronizing the render tools.';
COMMENT ON COLUMN public.nps_render_point.the_geom IS 'Contains the geometry for the point.';
COMMENT ON COLUMN public.nps_render_point.z_order IS 'Contains the display order of the points.  This is a calculated field, it is calclated from the "tags" field using the "nps_node_o2p_calculate_zorder" function.';
COMMENT ON COLUMN public.nps_render_point.unit_code IS 'The unit code of the park that contains this point';


-----------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.nps_node_o2p_calculate_zorder(text)
  RETURNS integer AS
$BODY$
DECLARE
  v_tag ALIAS for $1;
  v_zorder integer;
BEGIN

SELECT
  CASE
    WHEN v_tag = 'Visitor Center' THEN 40
    WHEN v_tag = 'Ranger Station' THEN 38
    WHEN v_tag = 'Information' THEN 36
    WHEN v_tag = 'Lodge' THEN 34
    WHEN v_tag = 'Campground' THEN 32
    WHEN v_tag = 'Food Service' THEN 30
    WHEN v_tag = 'Store' THEN 28
    WHEN v_tag = 'Picnic Site' THEN 26
    WHEN v_tag = 'Picnic Table' THEN 26
    WHEN v_tag = 'Trailhead' THEN 24
    WHEN v_tag = 'Car Parking' THEN 22
    WHEN v_tag = 'Restrooms' THEN 20
    ELSE 0
  END AS order
INTO
  v_zorder;

RETURN v_zorder;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.nps_node_o2p_calculate_zorder(text)
  OWNER TO postgres;
  ------------
  
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
  hstore(array_agg(key), array_agg(value))
FROM
 json_each_text(v_json)
INTO
  v_hstore;

 RETURN v_hstore;
END;
$json_to_hstore$
LANGUAGE plpgsql;
  
--
CREATE OR REPLACE FUNCTION public.o2p_get_name(
  hstore,
  character(1),
  boolean
)
  RETURNS text AS $o2p_get_name$
DECLARE
  v_hstore ALIAS for $1;
  v_member_type ALIAS FOR $2; -- Current not used, update this!
  v_all ALIAS for $3;
  v_name TEXT;
  v_tag_count bigint;
BEGIN

SELECT
  array_length(array_agg(key),1)
FROM
  unnest(akeys(v_hstore)) key
WHERE
  key NOT LIKE 'nps:%'
INTO
  v_tag_count;

IF v_tag_count > 0 THEN
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
            hstore_tag_list.name, 
            (SELECT hstore(array_agg(key), array_agg(hstore_tag_list.tags->key)) from unnest(akeys(hstore_tag_list.tags)) key WHERE key not like 'nps:%') tags,
            (SELECT array_length(array_agg(key),1) FROM unnest(akeys(hstore_tag_list.tags)) key WHERE key not like 'nps:%') hstore_len
          FROM
            (
              SELECT
                name,
                json_to_hstore(tags) tags
              FROM
                tag_list
              WHERE
                tag_list.geometry @> ARRAY['point'] AND
                (v_all OR (
                  tag_list.searchable is null OR
                  tag_list.searchable is true
                ))
            ) hstore_tag_list
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
  ELSE
    SELECT null INTO v_name;
  END IF;

 RETURN v_name;
END;
$o2p_get_name$
LANGUAGE plpgsql;
--------------------------------

--------------------------------
CREATE OR REPLACE VIEW public.nps_planet_osm_point_view AS 
SELECT
  "osm_id",
  "version",
  "name",
  "fcat",
  "tags", 
  "created", 
  "way",
  nps_node_o2p_calculate_zorder(fcat) as "z_order",
  COALESCE("unit_code", (
    -- If the unit_code is null, try to join it up
    SELECT
      LOWER(unit_code)
    FROM
      render_park_polys
    WHERE
      -- The projection for OSM is 900913, although we use 3857, and they are identical
      -- PostGIS requires a 'transform' between these two SRIDs when doing a comparison
      ST_Transform("base"."way", 3857) && "render_park_polys"."poly_geom" AND 
      ST_Contains("render_park_polys"."poly_geom",ST_Transform("base"."way", 3857))
    )) AS "unit_code"
FROM (
  SELECT
    "nodes"."id" AS "osm_id",
    "nodes"."version" AS "version",
    "nodes"."tags" -> 'name'::text AS "name",
    o2p_get_name("tags", 'N') AS "fcat",
    "tags" AS "tags",
    NOW()::timestamp without time zone AS "created",
    st_transform(nodes.geom, 900913) AS "way",
    "nodes"."tags" -> 'nps:unit_code'::text AS "unit_code"
  FROM
    "nodes"
  WHERE
    (
      SELECT
        array_length(array_agg("key"),1)
      FROM
        unnest(akeys(nodes.tags)) "key"
      WHERE
        "key" NOT LIKE 'nps:%'
    ) > 0
) "base"
WHERE
  "fcat" IS NOT NULL;
--------------------------------

-- Function: public.nps_pgs_update_o2p(bigint, character)

-- DROP FUNCTION public.nps_pgs_update_o2p(bigint, character);

CREATE OR REPLACE FUNCTION public.nps_pgs_update_o2p(bigint, character)
  RETURNS boolean AS
$BODY$
  DECLARE
    v_id ALIAS FOR $1;
    v_member_type ALIAS FOR $2;
    v_rel_id BIGINT;
  BEGIN
  
  -- Add any information that will be deleting / changing
  -- to the change log, which is used to keep the renderers synchronized
  INSERT INTO nps_change_log (
    SELECT
      v_id AS "osm_id",
      "nps_render_point"."version" AS "version",
      v_member_type AS "member_type",
      "nps_render_point"."the_geom" AS "way",
      "nps_render_point"."rendered" AS "created",
      NOW()::timestamp without time zone AS "change_time"
    FROM
       "nps_render_point"
    WHERE
      "osm_id" = v_id
  );
  -- TODO: Union with code to copy in values for polygons and lines
  
  -- Update this object in the nps o2p tables
    IF v_member_type = 'N' THEN

      DELETE FROM nps_render_point WHERE osm_id = v_id;
      INSERT INTO nps_render_point (
        SELECT
          "osm_id" AS "osm_id",
          "version" AS "version",
          "name" AS "name",
          "fcat" AS "type",
          "tags" AS "tags",
          "created" AS "rendered",
          "way" AS "the_geom",
          "z_order" AS "z_order",
          "unit_code" AS "unit_code"
        FROM nps_planet_osm_point_view
        WHERE osm_id = v_id
      );
      
      -- TODO: Add code to render polygons and lines
    END IF;

  RETURN true;
  END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.nps_pgs_update_o2p(bigint, character)
  OWNER TO osm;
