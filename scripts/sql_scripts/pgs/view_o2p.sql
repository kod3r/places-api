-- View: public.planet_osm_line_view

-- DROP VIEW public.planet_osm_line_view;

CREATE OR REPLACE VIEW public.planet_osm_line_view AS 
         SELECT ways.id AS osm_id,
            ways.tags -> 'access'::text AS access,
            ways.tags -> 'addr:housename'::text AS "addr:housename",
            ways.tags -> 'addr:housenumber'::text AS "addr:housenumber",
            ways.tags -> 'addr:interpolation'::text AS "addr:interpolation",
            ways.tags -> 'admin_level'::text AS admin_level,
            ways.tags -> 'aerialway'::text AS aerialway,
            ways.tags -> 'aeroway'::text AS aeroway,
            ways.tags -> 'amenity'::text AS amenity,
            ways.tags -> 'area'::text AS area,
            ways.tags -> 'barrier'::text AS barrier,
            ways.tags -> 'bicycle'::text AS bicycle,
            ways.tags -> 'brand'::text AS brand,
            ways.tags -> 'bridge'::text AS bridge,
            ways.tags -> 'boundary'::text AS boundary,
            ways.tags -> 'building'::text AS building,
            ways.tags -> 'construction'::text AS construction,
            ways.tags -> 'covered'::text AS covered,
            ways.tags -> 'culvert'::text AS culvert,
            ways.tags -> 'cutting'::text AS cutting,
            ways.tags -> 'denomination'::text AS denomination,
            ways.tags -> 'disused'::text AS disused,
            ways.tags -> 'embankment'::text AS embankment,
            ways.tags -> 'foot'::text AS foot,
            ways.tags -> 'generator:source'::text AS "generator:source",
            ways.tags -> 'harbour'::text AS harbour,
            ways.tags -> 'highway'::text AS highway,
            ways.tags -> 'historic'::text AS historic,
            ways.tags -> 'horse'::text AS horse,
            ways.tags -> 'intermittent'::text AS intermittent,
            ways.tags -> 'junction'::text AS junction,
            ways.tags -> 'landuse'::text AS landuse,
            ways.tags -> 'layer'::text AS layer,
            ways.tags -> 'leisure'::text AS leisure,
            ways.tags -> 'lock'::text AS lock,
            ways.tags -> 'man_made'::text AS man_made,
            ways.tags -> 'military'::text AS military,
            ways.tags -> 'motorcar'::text AS motorcar,
            ways.tags -> 'name'::text AS name,
            ways.tags -> 'natural'::text AS "natural",
            ways.tags -> 'office'::text AS office,
            ways.tags -> 'oneway'::text AS oneway,
            ways.tags -> 'operator'::text AS operator,
            ways.tags -> 'place'::text AS place,
            ways.tags -> 'population'::text AS population,
            ways.tags -> 'power'::text AS power,
            ways.tags -> 'power_source'::text AS power_source,
            ways.tags -> 'public_transport'::text AS public_transport,
            ways.tags -> 'railway'::text AS railway,
            ways.tags -> 'ref'::text AS ref,
            ways.tags -> 'religion'::text AS religion,
            ways.tags -> 'route'::text AS route,
            ways.tags -> 'service'::text AS service,
            ways.tags -> 'shop'::text AS shop,
            ways.tags -> 'sport'::text AS sport,
            ways.tags -> 'surface'::text AS surface,
            ways.tags -> 'toll'::text AS toll,
            ways.tags -> 'tourism'::text AS tourism,
            ways.tags -> 'tower:type'::text AS "tower:type",
            ways.tags -> 'tracktype'::text AS tracktype,
            ways.tags -> 'tunnel'::text AS tunnel,
            ways.tags -> 'water'::text AS water,
            ways.tags -> 'waterway'::text AS waterway,
            ways.tags -> 'wetland'::text AS wetland,
            ways.tags -> 'width'::text AS width,
            ways.tags -> 'wood'::text AS wood,
            o2p_calculate_zorder(ways.tags) AS z_order,
            st_area(st_transform(o2p_calculate_nodes_to_line(ways.nodes), 900913)) AS way_area,
            st_transform(o2p_calculate_nodes_to_line(ways.nodes), 900913) AS way
           FROM ways
          WHERE ways.tags <> ''::hstore AND
            ways.tags IS NOT NULL AND
            array_length(ways.nodes, 1) > 1 AND
            (
              exist(ways.tags, 'access'::text) OR
              exist(ways.tags, 'addr:housename'::text) OR
              exist(ways.tags, 'addr:housenumber'::text) OR
              exist(ways.tags, 'addr:interpolation'::text) OR
              exist(ways.tags, 'admin_level'::text) OR
              exist(ways.tags, 'aerialway'::text) OR
              (exist(ways.tags, 'aeroway'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
              (exist(ways.tags, 'amenity'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
              exist(ways.tags, 'barrier'::text) OR
              exist(ways.tags, 'brand'::text) OR
              exist(ways.tags, 'bridge'::text) OR
              exist(ways.tags, 'boundary'::text) OR
              (exist(ways.tags, 'building'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
              exist(ways.tags, 'construction'::text) OR
              exist(ways.tags, 'covered'::text) OR
              exist(ways.tags, 'culvert'::text) OR
              exist(ways.tags, 'cutting'::text) OR
              exist(ways.tags, 'denomination'::text) OR
              exist(ways.tags, 'disused'::text) OR
              exist(ways.tags, 'embankment'::text) OR
              exist(ways.tags, 'foot'::text) OR
              exist(ways.tags, 'generator:source'::text) OR
              (exist(ways.tags, 'harbour'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
              exist(ways.tags, 'highway'::text) OR
              (exist(ways.tags, 'historic'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
              exist(ways.tags, 'horse'::text) OR
              exist(ways.tags, 'intermittent'::text) OR
              exist(ways.tags, 'junction'::text) OR
              (exist(ways.tags, 'landuse'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
              exist(ways.tags, 'layer'::text) OR
              (exist(ways.tags, 'leisure'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
              exist(ways.tags, 'lock'::text) OR
              (exist(ways.tags, 'man_made'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
              (exist(ways.tags, 'military'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
              exist(ways.tags, 'motorcar'::text) OR
              exist(ways.tags, 'name'::text) OR
              (exist(ways.tags, 'natural'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
              (exist(ways.tags, 'office'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
              exist(ways.tags, 'oneway'::text) OR
              exist(ways.tags, 'operator'::text) OR
              (exist(ways.tags, 'place'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
              exist(ways.tags, 'population'::text) OR
              (exist(ways.tags, 'power'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
              exist(ways.tags, 'power_source'::text) OR
              (exist(ways.tags, 'public_transport'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
              exist(ways.tags, 'railway'::text) OR
              exist(ways.tags, 'ref'::text) OR
              exist(ways.tags, 'route'::text) OR
              exist(ways.tags, 'service'::text) OR
              (exist(ways.tags, 'shop'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
              (exist(ways.tags, 'sport'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
              exist(ways.tags, 'surface'::text) OR
              exist(ways.tags, 'toll'::text) OR
              (exist(ways.tags, 'tourism'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
              exist(ways.tags, 'tower:type'::text) OR
              exist(ways.tags, 'tracktype'::text) OR
              exist(ways.tags, 'tunnel'::text) OR
              (exist(ways.tags, 'water'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
              (exist(ways.tags, 'waterway'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
              exist(ways.tags, 'wetland'::text) OR
              exist(ways.tags, 'width'::text) OR
              exist(ways.tags, 'wood'::text))
UNION
         SELECT rel_line.osm_id,
            rel_line.tags -> 'access'::text AS access,
            rel_line.tags -> 'addr:housename'::text AS "addr:housename",
            rel_line.tags -> 'addr:housenumber'::text AS "addr:housenumber",
            rel_line.tags -> 'addr:interpolation'::text AS "addr:interpolation",
            rel_line.tags -> 'admin_level'::text AS admin_level,
            rel_line.tags -> 'aerialway'::text AS aerialway,
            rel_line.tags -> 'aeroway'::text AS aeroway,
            rel_line.tags -> 'amenity'::text AS amenity,
            rel_line.tags -> 'area'::text AS area,
            rel_line.tags -> 'barrier'::text AS barrier,
            rel_line.tags -> 'bicycle'::text AS bicycle,
            rel_line.tags -> 'brand'::text AS brand,
            rel_line.tags -> 'bridge'::text AS bridge,
            rel_line.tags -> 'boundary'::text AS boundary,
            rel_line.tags -> 'building'::text AS building,
            rel_line.tags -> 'construction'::text AS construction,
            rel_line.tags -> 'covered'::text AS covered,
            rel_line.tags -> 'culvert'::text AS culvert,
            rel_line.tags -> 'cutting'::text AS cutting,
            rel_line.tags -> 'denomination'::text AS denomination,
            rel_line.tags -> 'disused'::text AS disused,
            rel_line.tags -> 'embankment'::text AS embankment,
            rel_line.tags -> 'foot'::text AS foot,
            rel_line.tags -> 'generator:source'::text AS "generator:source",
            rel_line.tags -> 'harbour'::text AS harbour,
            rel_line.tags -> 'highway'::text AS highway,
            rel_line.tags -> 'historic'::text AS historic,
            rel_line.tags -> 'horse'::text AS horse,
            rel_line.tags -> 'intermittent'::text AS intermittent,
            rel_line.tags -> 'junction'::text AS junction,
            rel_line.tags -> 'landuse'::text AS landuse,
            rel_line.tags -> 'layer'::text AS layer,
            rel_line.tags -> 'leisure'::text AS leisure,
            rel_line.tags -> 'lock'::text AS lock,
            rel_line.tags -> 'man_made'::text AS man_made,
            rel_line.tags -> 'military'::text AS military,
            rel_line.tags -> 'motorcar'::text AS motorcar,
            rel_line.tags -> 'name'::text AS name,
            rel_line.tags -> 'natural'::text AS "natural",
            rel_line.tags -> 'office'::text AS office,
            rel_line.tags -> 'oneway'::text AS oneway,
            rel_line.tags -> 'operator'::text AS operator,
            rel_line.tags -> 'place'::text AS place,
            rel_line.tags -> 'population'::text AS population,
            rel_line.tags -> 'power'::text AS power,
            rel_line.tags -> 'power_source'::text AS power_source,
            rel_line.tags -> 'public_transport'::text AS public_transport,
            rel_line.tags -> 'railway'::text AS railway,
            rel_line.tags -> 'ref'::text AS ref,
            rel_line.tags -> 'religion'::text AS religion,
            rel_line.tags -> 'route'::text AS route,
            rel_line.tags -> 'service'::text AS service,
            rel_line.tags -> 'shop'::text AS shop,
            rel_line.tags -> 'sport'::text AS sport,
            rel_line.tags -> 'surface'::text AS surface,
            rel_line.tags -> 'toll'::text AS toll,
            rel_line.tags -> 'tourism'::text AS tourism,
            rel_line.tags -> 'tower:type'::text AS "tower:type",
            rel_line.tags -> 'tracktype'::text AS tracktype,
            rel_line.tags -> 'tunnel'::text AS tunnel,
            rel_line.tags -> 'water'::text AS water,
            rel_line.tags -> 'waterway'::text AS waterway,
            rel_line.tags -> 'wetland'::text AS wetland,
            rel_line.tags -> 'width'::text AS width,
            rel_line.tags -> 'wood'::text AS wood,
            rel_line.z_order,
            st_area(rel_line.way) AS way_area,
            rel_line.way
           FROM ( SELECT relation_members.relation_id * (-1) AS osm_id,
                    relations.tags,
                    o2p_calculate_zorder(relations.tags) AS z_order,
                    st_transform(unnest(o2p_aggregate_line_relation(relation_members.relation_id)), 900913) AS way
                   FROM ways
              JOIN relation_members ON ways.id = relation_members.member_id
         JOIN relations ON relation_members.relation_id = relations.id
        WHERE
          relations.tags <> ''::hstore AND
          relations.tags IS NOT NULL AND
          array_length(ways.nodes, 1) > 1 AND
          exist(relations.tags, 'type'::text) AND ((relations.tags -> 'type'::text) = 'multipolygon'::text OR
          (relations.tags -> 'type'::text) = 'boundary'::text OR (relations.tags -> 'type'::text) = 'route'::text) AND
          (
            exist(relations.tags, 'access'::text) OR
            exist(relations.tags, 'addr:housename'::text) OR
            exist(relations.tags, 'addr:housenumber'::text) OR
            exist(relations.tags, 'addr:interpolation'::text) OR
            exist(relations.tags, 'admin_level'::text) OR
            exist(relations.tags, 'aerialway'::text) OR
            (exist(relations.tags, 'aeroway'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
            (exist(relations.tags, 'amenity'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
            exist(relations.tags, 'barrier'::text) OR
            exist(relations.tags, 'brand'::text) OR
            exist(relations.tags, 'bridge'::text) OR
            exist(relations.tags, 'boundary'::text) OR
            (exist(relations.tags, 'building'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
            exist(relations.tags, 'construction'::text) OR
            exist(relations.tags, 'covered'::text) OR
            exist(relations.tags, 'culvert'::text) OR
            exist(relations.tags, 'cutting'::text) OR
            exist(relations.tags, 'denomination'::text) OR
            exist(relations.tags, 'disused'::text) OR
            exist(relations.tags, 'embankment'::text) OR
            exist(relations.tags, 'foot'::text) OR
            exist(relations.tags, 'generator:source'::text) OR
            (exist(relations.tags, 'harbour'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
            exist(relations.tags, 'highway'::text) OR
            (exist(relations.tags, 'historic'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
            exist(relations.tags, 'horse'::text) OR
            exist(relations.tags, 'intermittent'::text) OR
            exist(relations.tags, 'junction'::text) OR
            (exist(relations.tags, 'landuse'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
            exist(relations.tags, 'layer'::text) OR
            (exist(relations.tags, 'leisure'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
            exist(relations.tags, 'lock'::text) OR
            (exist(relations.tags, 'man_made'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
            (exist(relations.tags, 'military'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
            exist(relations.tags, 'motorcar'::text) OR
            exist(relations.tags, 'name'::text) OR
            (exist(relations.tags, 'natural'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
            (exist(relations.tags, 'office'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
            exist(relations.tags, 'oneway'::text) OR
            exist(relations.tags, 'operator'::text) OR
            (exist(relations.tags, 'place'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
            exist(relations.tags, 'population'::text) OR
            (exist(relations.tags, 'power'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
            exist(relations.tags, 'power_source'::text) OR
            (exist(relations.tags, 'public_transport'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
            exist(relations.tags, 'railway'::text) OR
            exist(relations.tags, 'ref'::text) OR
            exist(relations.tags, 'route'::text) OR
            exist(relations.tags, 'service'::text) OR
            (exist(relations.tags, 'shop'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
            (exist(relations.tags, 'sport'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
            exist(relations.tags, 'surface'::text) OR
            exist(relations.tags, 'toll'::text) OR
            (exist(relations.tags, 'tourism'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
            exist(relations.tags, 'tower:type'::text) OR
            exist(relations.tags, 'tracktype'::text) OR
            exist(relations.tags, 'tunnel'::text) OR
            (exist(relations.tags, 'water'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
            (exist(relations.tags, 'waterway'::text) AND ways.nodes[1] <> ways.nodes[array_length(ways.nodes, 1)]) OR
            exist(relations.tags, 'wetland'::text) OR
            exist(relations.tags, 'width'::text) OR
            exist(relations.tags, 'wood'::text)
         )) rel_line;

ALTER TABLE public.planet_osm_line_view
  OWNER TO postgres;


-- View: public.planet_osm_point_view

-- DROP VIEW public.planet_osm_point_view;

CREATE OR REPLACE VIEW public.planet_osm_point_view AS 
 SELECT nodes.id AS osm_id,
    nodes.tags -> 'access'::text AS access,
    nodes.tags -> 'addr:housename'::text AS "addr:housename",
    nodes.tags -> 'addr:housenumber'::text AS "addr:housenumber",
    nodes.tags -> 'addr:interpolation'::text AS "addr:interpolation",
    nodes.tags -> 'admin_level'::text AS admin_level,
    nodes.tags -> 'aerialway'::text AS aerialway,
    nodes.tags -> 'aeroway'::text AS aeroway,
    nodes.tags -> 'amenity'::text AS amenity,
    nodes.tags -> 'area'::text AS area,
    nodes.tags -> 'barrier'::text AS barrier,
    nodes.tags -> 'bicycle'::text AS bicycle,
    nodes.tags -> 'brand'::text AS brand,
    nodes.tags -> 'bridge'::text AS bridge,
    nodes.tags -> 'boundary'::text AS boundary,
    nodes.tags -> 'building'::text AS building,
    nodes.tags -> 'construction'::text AS construction,
    nodes.tags -> 'covered'::text AS covered,
    nodes.tags -> 'culvert'::text AS culvert,
    nodes.tags -> 'cutting'::text AS cutting,
    nodes.tags -> 'denomination'::text AS denomination,
    nodes.tags -> 'disused'::text AS disused,
    nodes.tags -> 'embankment'::text AS embankment,
    nodes.tags -> 'foot'::text AS foot,
    nodes.tags -> 'generator:source'::text AS "generator:source",
    nodes.tags -> 'harbour'::text AS harbour,
    nodes.tags -> 'highway'::text AS highway,
    nodes.tags -> 'historic'::text AS historic,
    nodes.tags -> 'horse'::text AS horse,
    nodes.tags -> 'intermittent'::text AS intermittent,
    nodes.tags -> 'junction'::text AS junction,
    nodes.tags -> 'landuse'::text AS landuse,
    nodes.tags -> 'layer'::text AS layer,
    nodes.tags -> 'leisure'::text AS leisure,
    nodes.tags -> 'lock'::text AS lock,
    nodes.tags -> 'man_made'::text AS man_made,
    nodes.tags -> 'military'::text AS military,
    nodes.tags -> 'motorcar'::text AS motorcar,
    nodes.tags -> 'name'::text AS name,
    nodes.tags -> 'natural'::text AS "natural",
    nodes.tags -> 'office'::text AS office,
    nodes.tags -> 'oneway'::text AS oneway,
    nodes.tags -> 'operator'::text AS operator,
    nodes.tags -> 'place'::text AS place,
    nodes.tags -> 'population'::text AS population,
    nodes.tags -> 'power'::text AS power,
    nodes.tags -> 'power_source'::text AS power_source,
    nodes.tags -> 'public_transport'::text AS public_transport,
    nodes.tags -> 'railway'::text AS railway,
    nodes.tags -> 'ref'::text AS ref,
    nodes.tags -> 'religion'::text AS religion,
    nodes.tags -> 'route'::text AS route,
    nodes.tags -> 'service'::text AS service,
    nodes.tags -> 'shop'::text AS shop,
    nodes.tags -> 'sport'::text AS sport,
    nodes.tags -> 'surface'::text AS surface,
    nodes.tags -> 'toll'::text AS toll,
    nodes.tags -> 'tourism'::text AS tourism,
    nodes.tags -> 'tower:type'::text AS "tower:type",
    nodes.tags -> 'tracktype'::text AS tracktype,
    nodes.tags -> 'tunnel'::text AS tunnel,
    nodes.tags -> 'water'::text AS water,
    nodes.tags -> 'waterway'::text AS waterway,
    nodes.tags -> 'wetland'::text AS wetland,
    nodes.tags -> 'width'::text AS width,
    nodes.tags -> 'wood'::text AS wood,
    o2p_calculate_zorder(nodes.tags) AS z_order,
    st_transform(nodes.geom, 900913) AS way
   FROM nodes
  WHERE nodes.tags <> ''::hstore AND 
  nodes.tags IS NOT NULL AND 
  (
      exist(nodes.tags, 'access'::text) OR
      exist(nodes.tags, 'addr:housename'::text) OR
      exist(nodes.tags, 'addr:housenumber'::text) OR
      exist(nodes.tags, 'addr:interpolation'::text) OR
      exist(nodes.tags, 'admin_level'::text) OR
      exist(nodes.tags, 'aerialway'::text) OR
      exist(nodes.tags, 'aeroway'::text) OR
      exist(nodes.tags, 'amenity'::text) OR
      exist(nodes.tags, 'barrier'::text) OR
      exist(nodes.tags, 'brand'::text) OR
      exist(nodes.tags, 'bridge'::text) OR
      exist(nodes.tags, 'boundary'::text) OR
      exist(nodes.tags, 'building'::text) OR
      exist(nodes.tags, 'capital'::text) OR
      exist(nodes.tags, 'construction'::text) OR
      exist(nodes.tags, 'covered'::text) OR
      exist(nodes.tags, 'culvert'::text) OR
      exist(nodes.tags, 'cutting'::text) OR
      exist(nodes.tags, 'denomination'::text) OR
      exist(nodes.tags, 'disused'::text) OR
      exist(nodes.tags, 'ele'::text) OR
      exist(nodes.tags, 'embankment'::text) OR
      exist(nodes.tags, 'foot'::text) OR
      exist(nodes.tags, 'generator:source'::text) OR
      exist(nodes.tags, 'harbour'::text) OR
      exist(nodes.tags, 'highway'::text) OR
      exist(nodes.tags, 'historic'::text) OR
      exist(nodes.tags, 'horse'::text) OR
      exist(nodes.tags, 'intermittent'::text) OR
      exist(nodes.tags, 'junction'::text) OR
      exist(nodes.tags, 'landuse'::text) OR
      exist(nodes.tags, 'layer'::text) OR
      exist(nodes.tags, 'leisure'::text) OR
      exist(nodes.tags, 'lock'::text) OR
      exist(nodes.tags, 'man_made'::text) OR
      exist(nodes.tags, 'military'::text) OR
      exist(nodes.tags, 'motorcar'::text) OR
      exist(nodes.tags, 'name'::text) OR
      exist(nodes.tags, 'natural'::text) OR
      exist(nodes.tags, 'office'::text) OR
      exist(nodes.tags, 'oneway'::text) OR
      exist(nodes.tags, 'operator'::text) OR
      exist(nodes.tags, 'place'::text) OR
      exist(nodes.tags, 'population'::text) OR
      exist(nodes.tags, 'power'::text) OR
      exist(nodes.tags, 'power_source'::text) OR
      exist(nodes.tags, 'public_transport'::text) OR
      exist(nodes.tags, 'railway'::text) OR
      exist(nodes.tags, 'ref'::text) OR
      exist(nodes.tags, 'route'::text) OR
      exist(nodes.tags, 'service'::text) OR
      exist(nodes.tags, 'shop'::text) OR
      exist(nodes.tags, 'sport'::text) OR
      exist(nodes.tags, 'surface'::text) OR
      exist(nodes.tags, 'toll'::text) OR
      exist(nodes.tags, 'tourism'::text) OR
      exist(nodes.tags, 'tower:type'::text) OR
      exist(nodes.tags, 'tunnel'::text) OR
      exist(nodes.tags, 'water'::text) OR
      exist(nodes.tags, 'waterway'::text) OR
      exist(nodes.tags, 'wetland'::text) OR
      exist(nodes.tags, 'width'::text) OR
      exist(nodes.tags, 'wood'::text)
    );

ALTER TABLE public.planet_osm_point_view
  OWNER TO postgres;


-- View: public.planet_osm_polygon_view

-- DROP VIEW public.planet_osm_polygon_view;

CREATE OR REPLACE VIEW public.planet_osm_polygon_view AS 
         SELECT ways.id AS osm_id,
            ways.tags -> 'access'::text AS access,
            ways.tags -> 'addr:housename'::text AS "addr:housename",
            ways.tags -> 'addr:housenumber'::text AS "addr:housenumber",
            ways.tags -> 'addr:interpolation'::text AS "addr:interpolation",
            ways.tags -> 'admin_level'::text AS admin_level,
            ways.tags -> 'aerialway'::text AS aerialway,
            ways.tags -> 'aeroway'::text AS aeroway,
            ways.tags -> 'amenity'::text AS amenity,
            ways.tags -> 'area'::text AS area,
            ways.tags -> 'barrier'::text AS barrier,
            ways.tags -> 'bicycle'::text AS bicycle,
            ways.tags -> 'brand'::text AS brand,
            ways.tags -> 'bridge'::text AS bridge,
            ways.tags -> 'boundary'::text AS boundary,
            ways.tags -> 'building'::text AS building,
            ways.tags -> 'construction'::text AS construction,
            ways.tags -> 'covered'::text AS covered,
            ways.tags -> 'culvert'::text AS culvert,
            ways.tags -> 'cutting'::text AS cutting,
            ways.tags -> 'denomination'::text AS denomination,
            ways.tags -> 'disused'::text AS disused,
            ways.tags -> 'embankment'::text AS embankment,
            ways.tags -> 'foot'::text AS foot,
            ways.tags -> 'generator:source'::text AS "generator:source",
            ways.tags -> 'harbour'::text AS harbour,
            ways.tags -> 'highway'::text AS highway,
            ways.tags -> 'historic'::text AS historic,
            ways.tags -> 'horse'::text AS horse,
            ways.tags -> 'intermittent'::text AS intermittent,
            ways.tags -> 'junction'::text AS junction,
            ways.tags -> 'landuse'::text AS landuse,
            ways.tags -> 'layer'::text AS layer,
            ways.tags -> 'leisure'::text AS leisure,
            ways.tags -> 'lock'::text AS lock,
            ways.tags -> 'man_made'::text AS man_made,
            ways.tags -> 'military'::text AS military,
            ways.tags -> 'motorcar'::text AS motorcar,
            ways.tags -> 'name'::text AS name,
            ways.tags -> 'natural'::text AS "natural",
            ways.tags -> 'office'::text AS office,
            ways.tags -> 'oneway'::text AS oneway,
            ways.tags -> 'operator'::text AS operator,
            ways.tags -> 'place'::text AS place,
            ways.tags -> 'population'::text AS population,
            ways.tags -> 'power'::text AS power,
            ways.tags -> 'power_source'::text AS power_source,
            ways.tags -> 'public_transport'::text AS public_transport,
            ways.tags -> 'railway'::text AS railway,
            ways.tags -> 'ref'::text AS ref,
            ways.tags -> 'religion'::text AS religion,
            ways.tags -> 'route'::text AS route,
            ways.tags -> 'service'::text AS service,
            ways.tags -> 'shop'::text AS shop,
            ways.tags -> 'sport'::text AS sport,
            ways.tags -> 'surface'::text AS surface,
            ways.tags -> 'toll'::text AS toll,
            ways.tags -> 'tourism'::text AS tourism,
            ways.tags -> 'tower:type'::text AS "tower:type",
            ways.tags -> 'tracktype'::text AS tracktype,
            ways.tags -> 'tunnel'::text AS tunnel,
            ways.tags -> 'water'::text AS water,
            ways.tags -> 'waterway'::text AS waterway,
            ways.tags -> 'wetland'::text AS wetland,
            ways.tags -> 'width'::text AS width,
            ways.tags -> 'wood'::text AS wood,
            o2p_calculate_zorder(ways.tags) AS z_order,
            st_area(st_makepolygon(st_transform(o2p_calculate_nodes_to_line(ways.nodes), 900913))) AS way_area,
            st_makepolygon(st_transform(o2p_calculate_nodes_to_line(ways.nodes), 900913)) AS way
           FROM ways
          WHERE NOT (EXISTS (
            SELECT
              1
            FROM
              relation_members JOIN relations 
              ON relation_members.relation_id = relations.id
            WHERE relation_members.member_id = ways.id AND
              relation_members.member_type = 'W'::bpchar AND
                (
                  (relations.tags -> 'type'::text) = 'multipolygon'::text OR
                  (relations.tags -> 'type'::text) = 'boundary'::text OR
                  (relations.tags -> 'type'::text) = 'route'::text
                )
              )
        ) AND ways.tags <> ''::hstore AND
          ways.tags IS NOT NULL AND
          ST_NPoints(o2p_calculate_nodes_to_line(ways.nodes)) >= 4 AND
          ST_IsClosed(o2p_calculate_nodes_to_line(ways.nodes)) AND
          array_length(ways.nodes, 1) > 3 AND
          (
            exist(ways.tags, 'aeroway'::text) OR
            exist(ways.tags, 'amenity'::text) OR
            exist(ways.tags, 'building'::text) OR
            exist(ways.tags, 'harbour'::text) OR
            exist(ways.tags, 'historic'::text) OR
            exist(ways.tags, 'landuse'::text) OR
            exist(ways.tags, 'leisure'::text) OR
            exist(ways.tags, 'man_made'::text) OR
            exist(ways.tags, 'military'::text) OR
            exist(ways.tags, 'natural'::text) OR
            exist(ways.tags, 'office'::text) OR
            exist(ways.tags, 'place'::text) OR
            exist(ways.tags, 'power'::text) OR
            exist(ways.tags, 'public_transport'::text) OR
            exist(ways.tags, 'shop'::text) OR
            exist(ways.tags, 'sport'::text) OR
            exist(ways.tags, 'tourism'::text) OR
            exist(ways.tags, 'water'::text) OR
            exist(ways.tags, 'waterway'::text) OR
            exist(ways.tags, 'wetland'::text)
          )
UNION
         SELECT rel_poly.osm_id,
            rel_poly.tags -> 'access'::text AS access,
            rel_poly.tags -> 'addr:housename'::text AS "addr:housename",
            rel_poly.tags -> 'addr:housenumber'::text AS "addr:housenumber",
            rel_poly.tags -> 'addr:interpolation'::text AS "addr:interpolation",
            rel_poly.tags -> 'admin_level'::text AS admin_level,
            rel_poly.tags -> 'aerialway'::text AS aerialway,
            rel_poly.tags -> 'aeroway'::text AS aeroway,
            rel_poly.tags -> 'amenity'::text AS amenity,
            rel_poly.tags -> 'area'::text AS area,
            rel_poly.tags -> 'barrier'::text AS barrier,
            rel_poly.tags -> 'bicycle'::text AS bicycle,
            rel_poly.tags -> 'brand'::text AS brand,
            rel_poly.tags -> 'bridge'::text AS bridge,
            rel_poly.tags -> 'boundary'::text AS boundary,
            rel_poly.tags -> 'building'::text AS building,
            rel_poly.tags -> 'construction'::text AS construction,
            rel_poly.tags -> 'covered'::text AS covered,
            rel_poly.tags -> 'culvert'::text AS culvert,
            rel_poly.tags -> 'cutting'::text AS cutting,
            rel_poly.tags -> 'denomination'::text AS denomination,
            rel_poly.tags -> 'disused'::text AS disused,
            rel_poly.tags -> 'embankment'::text AS embankment,
            rel_poly.tags -> 'foot'::text AS foot,
            rel_poly.tags -> 'generator:source'::text AS "generator:source",
            rel_poly.tags -> 'harbour'::text AS harbour,
            rel_poly.tags -> 'highway'::text AS highway,
            rel_poly.tags -> 'historic'::text AS historic,
            rel_poly.tags -> 'horse'::text AS horse,
            rel_poly.tags -> 'intermittent'::text AS intermittent,
            rel_poly.tags -> 'junction'::text AS junction,
            rel_poly.tags -> 'landuse'::text AS landuse,
            rel_poly.tags -> 'layer'::text AS layer,
            rel_poly.tags -> 'leisure'::text AS leisure,
            rel_poly.tags -> 'lock'::text AS lock,
            rel_poly.tags -> 'man_made'::text AS man_made,
            rel_poly.tags -> 'military'::text AS military,
            rel_poly.tags -> 'motorcar'::text AS motorcar,
            rel_poly.tags -> 'name'::text AS name,
            rel_poly.tags -> 'natural'::text AS "natural",
            rel_poly.tags -> 'office'::text AS office,
            rel_poly.tags -> 'oneway'::text AS oneway,
            rel_poly.tags -> 'operator'::text AS operator,
            rel_poly.tags -> 'place'::text AS place,
            rel_poly.tags -> 'population'::text AS population,
            rel_poly.tags -> 'power'::text AS power,
            rel_poly.tags -> 'power_source'::text AS power_source,
            rel_poly.tags -> 'public_transport'::text AS public_transport,
            rel_poly.tags -> 'railway'::text AS railway,
            rel_poly.tags -> 'ref'::text AS ref,
            rel_poly.tags -> 'religion'::text AS religion,
            rel_poly.tags -> 'route'::text AS route,
            rel_poly.tags -> 'service'::text AS service,
            rel_poly.tags -> 'shop'::text AS shop,
            rel_poly.tags -> 'sport'::text AS sport,
            rel_poly.tags -> 'surface'::text AS surface,
            rel_poly.tags -> 'toll'::text AS toll,
            rel_poly.tags -> 'tourism'::text AS tourism,
            rel_poly.tags -> 'tower:type'::text AS "tower:type",
            rel_poly.tags -> 'tracktype'::text AS tracktype,
            rel_poly.tags -> 'tunnel'::text AS tunnel,
            rel_poly.tags -> 'water'::text AS water,
            rel_poly.tags -> 'waterway'::text AS waterway,
            rel_poly.tags -> 'wetland'::text AS wetland,
            rel_poly.tags -> 'width'::text AS width,
            rel_poly.tags -> 'wood'::text AS wood,
            rel_poly.z_order,
            st_area(rel_poly.way) AS way_area,
            rel_poly.way
           FROM ( SELECT relation_members.relation_id * (-1) AS osm_id,
                    ways.tags,
                    o2p_calculate_zorder(relations.tags) AS z_order,
                    st_transform(unnest(o2p_aggregate_polygon_relation(relation_members.relation_id)), 900913) AS way
                   FROM ways
              JOIN relation_members ON ways.id = relation_members.member_id
         JOIN relations ON relation_members.relation_id = relations.id
        WHERE
          relations.tags <> ''::hstore AND
          relations.tags IS NOT NULL AND
          ST_NPoints(o2p_calculate_nodes_to_line(ways.nodes)) >= 4 AND
          ST_IsClosed(o2p_calculate_nodes_to_line(ways.nodes)) AND
          array_length(ways.nodes, 1) > 3 AND
          exist(relations.tags, 'type'::text) AND
          (
            (relations.tags -> 'type'::text) = 'multipolygon'::text OR
            (relations.tags -> 'type'::text) = 'boundary'::text OR
            (relations.tags -> 'type'::text) = 'route'::text OR
            exist(relations.tags, 'aeroway'::text) OR
            exist(relations.tags, 'amenity'::text) OR
            exist(relations.tags, 'building'::text) OR
            exist(relations.tags, 'harbour'::text) OR
            exist(relations.tags, 'historic'::text) OR
            exist(relations.tags, 'landuse'::text) OR
            exist(relations.tags, 'leisure'::text) OR
            exist(relations.tags, 'man_made'::text) OR
            exist(relations.tags, 'military'::text) OR
            exist(relations.tags, 'natural'::text) OR
            exist(relations.tags, 'office'::text) OR
            exist(relations.tags, 'place'::text) OR
            exist(relations.tags, 'power'::text) OR
            exist(relations.tags, 'public_transport'::text) OR
            exist(relations.tags, 'shop'::text) OR
            exist(relations.tags, 'sport'::text) OR
            exist(relations.tags, 'tourism'::text) OR
            exist(relations.tags, 'water'::text) OR
            exist(relations.tags, 'waterway'::text) OR
            exist(ways.tags, 'wetland'::text)
         )
        ) rel_poly;

-- View: public.planet_osm_roads_view

-- DROP VIEW public.planet_osm_roads_view;

CREATE OR REPLACE VIEW public.planet_osm_roads_view AS 
 SELECT planet_osm_line_view.osm_id,
    planet_osm_line_view.access,
    planet_osm_line_view."addr:housename",
    planet_osm_line_view."addr:housenumber",
    planet_osm_line_view."addr:interpolation",
    planet_osm_line_view.admin_level,
    planet_osm_line_view.aerialway,
    planet_osm_line_view.aeroway,
    planet_osm_line_view.amenity,
    planet_osm_line_view.area,
    planet_osm_line_view.barrier,
    planet_osm_line_view.bicycle,
    planet_osm_line_view.brand,
    planet_osm_line_view.bridge,
    planet_osm_line_view.boundary,
    planet_osm_line_view.building,
    planet_osm_line_view.construction,
    planet_osm_line_view.covered,
    planet_osm_line_view.culvert,
    planet_osm_line_view.cutting,
    planet_osm_line_view.denomination,
    planet_osm_line_view.disused,
    planet_osm_line_view.embankment,
    planet_osm_line_view.foot,
    planet_osm_line_view."generator:source",
    planet_osm_line_view.harbour,
    planet_osm_line_view.highway,
    planet_osm_line_view.historic,
    planet_osm_line_view.horse,
    planet_osm_line_view.intermittent,
    planet_osm_line_view.junction,
    planet_osm_line_view.landuse,
    planet_osm_line_view.layer,
    planet_osm_line_view.leisure,
    planet_osm_line_view.lock,
    planet_osm_line_view.man_made,
    planet_osm_line_view.military,
    planet_osm_line_view.motorcar,
    planet_osm_line_view.name,
    planet_osm_line_view."natural",
    planet_osm_line_view.office,
    planet_osm_line_view.oneway,
    planet_osm_line_view.operator,
    planet_osm_line_view.place,
    planet_osm_line_view.population,
    planet_osm_line_view.power,
    planet_osm_line_view.power_source,
    planet_osm_line_view.public_transport,
    planet_osm_line_view.railway,
    planet_osm_line_view.ref,
    planet_osm_line_view.religion,
    planet_osm_line_view.route,
    planet_osm_line_view.service,
    planet_osm_line_view.shop,
    planet_osm_line_view.sport,
    planet_osm_line_view.surface,
    planet_osm_line_view.toll,
    planet_osm_line_view.tourism,
    planet_osm_line_view."tower:type",
    planet_osm_line_view.tracktype,
    planet_osm_line_view.tunnel,
    planet_osm_line_view.water,
    planet_osm_line_view.waterway,
    planet_osm_line_view.wetland,
    planet_osm_line_view.width,
    planet_osm_line_view.wood,
    planet_osm_line_view.z_order,
    planet_osm_line_view.way_area,
    planet_osm_line_view.way
   FROM planet_osm_line_view
  WHERE
    planet_osm_line_view.highway IS NOT NULL OR
    planet_osm_line_view.railway IS NOT NULL OR
    planet_osm_line_view.boundary IS NOT NULL;
