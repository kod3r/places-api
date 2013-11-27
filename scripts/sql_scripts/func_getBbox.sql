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
      current_nodes.id as node_id
    FROM
      current_nodes
    WHERE
      current_nodes.latitude > v_minLat * 10000000
      AND current_nodes.longitude > v_minLon * 10000000
      AND current_nodes.latitude < v_maxLat * 10000000
      AND current_nodes.longitude < v_maxLon * 10000000
    LIMIT
      v_max_number_of_nodes;

    IF (SELECT COUNT(*)<v_max_number_of_nodes FROM nodes_in_bbox) THEN

    CREATE LOCAL TEMP TABLE ways_in_bbox ON COMMIT DROP AS
    SELECT DISTINCT
      current_way_nodes.way_id AS way_id
    FROM
      nodes_in_bbox
    JOIN
      current_way_nodes ON nodes_in_bbox.node_id = current_way_nodes.node_id;

    CREATE LOCAL TEMP TABLE nodes_in_ways_in_bbox ON COMMIT DROP AS
    SELECT DISTINCT
      node_id
    FROM
      current_way_nodes
      JOIN ways_in_bbox
        ON current_way_nodes.way_id = ways_in_bbox.way_id;
    
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
        min(current_nodes.latitude) as minLat,
        min(current_nodes.longitude) as minLon,
        max(current_nodes.latitude) as maxLat,
        min(current_nodes.longitude) as maxLon
      FROM
       nodes_in_query
       JOIN current_nodes
       ON nodes_in_query.node_id = current_nodes.id
      ) bboxBounds INTO v_bounds;

    CREATE LOCAL TEMP TABLE relations_in_bbox ON COMMIT DROP AS
    SELECT DISTINCT
      current_relation_members.relation_id
    FROM
      current_relation_members
      JOIN ways_in_bbox
        ON current_relation_members.member_id = ways_in_bbox.way_id
      WHERE
        lower(current_relation_members.member_type::text) = 'way'
    UNION
      SELECT DISTINCT
        current_relation_members.relation_id
      FROM
        current_relation_members
        JOIN nodes_in_query
          ON current_relation_members.member_id = nodes_in_query.node_id
      WHERE
          lower(current_relation_members.member_type::text) = 'node';

    SELECT json_agg(to_json(bboxNodes)) FROM (
    SELECT
      api_current_nodes.*
    FROM
      api_current_nodes
      JOIN nodes_in_query
        ON api_current_nodes.id = nodes_in_query.node_id
    WHERE
      api_current_nodes.visible = 't'
    ) bboxNodes
    INTO v_nodes;

    SELECT json_agg(to_json(bboxWays)) FROM (
    SELECT
      api_current_ways.*
    FROM
      api_current_ways
      JOIN ways_in_bbox
        ON api_current_ways.id = ways_in_bbox.way_id
      WHERE
        api_current_ways.visible = 't'
    ) bboxWays
    INTO v_ways;

    SELECT json_agg(to_json(bboxRelations)) FROM (
    SELECT
      api_current_relations.*
    FROM
      api_current_relations
      JOIN relations_in_bbox
        ON api_current_relations.id = relations_in_bbox.relation_id
      WHERE
        api_current_relations.visible = 't'
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
