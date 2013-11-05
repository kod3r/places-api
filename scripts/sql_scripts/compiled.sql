-- Compiled on Tue Nov 5 16:25:58 MST 2013

-- sequences
-- sequences.sql
-- nodes
CREATE SEQUENCE node_id_seq;
SELECT setval('node_id_seq', (SELECT max(node_id)+1 from nodes));

-- ways
CREATE SEQUENCE way_id_seq;
SELECT setval('way_id_seq', (SELECT max(way_id)+1 from ways));

-- relations
CREATE SEQUENCE relation_id_seq;
SELECT setval('relation_id_seq', (SELECT max(relation_id)+1 from relations));


-- changesets
SELECT setval('changesets_id_seq', (SELECT max(id)+1 from changesets));

-- types
-- types.sql
-- Type for map bbox return
DROP TYPE IF EXISTS osmMap CASCADE;
CREATE TYPE osmMap AS (bounds json, node json, way json, relation json);

-- node update/insert function
DROP TYPE IF EXISTS diffResult CASCADE;
CREATE TYPE diffResult AS (old_id bigint, new_id bigint, new_version bigint);


-- views
-- views.sql
-- VIEWS

-- Nodes
DROP VIEW IF EXISTS api_current_nodes;
CREATE VIEW api_current_nodes AS
SELECT
  current_nodes.id as id,
  current_nodes.visible,
  current_nodes.version,
  current_nodes.changeset_id as changeset,
  current_nodes.timestamp AT TIME ZONE 'UTC' as timestamp,
  users.display_name as user,
  changesets.user_id as uid,
  current_nodes.latitude/10000000::float as lat,
  current_nodes.longitude/10000000::float as lon,
  (SELECT json_agg(tags) from (SELECT k, v FROM node_tags WHERE node_id = current_nodes.id) tags) AS tag
FROM
  current_nodes
  JOIN changesets
    ON current_nodes.changeset_id = changesets.id
     JOIN users
       ON changesets.user_id = users.id;

-- Ways
DROP VIEW IF EXISTS api_current_ways;
CREATE VIEW api_current_ways AS
SELECT
  current_ways.id AS id,
  current_ways.visible AS visible,
  current_ways.version AS VERSION,
  current_ways.changeset_id AS changeset,
  current_ways.timestamp AT TIME ZONE 'UTC' AS TIMESTAMP,
  users.display_name AS USER,
  changesets.user_id AS uid,
  (SELECT json_agg(nodes) FROM (
    SELECT node_id AS ref
    FROM current_way_nodes
    WHERE current_way_nodes.way_id = current_ways.id
      AND version = current_ways.version
    ORDER BY sequence_id
    ) nodes
  ) AS nd,
  (SELECT json_agg(tags) FROM (
      SELECT k, v
      FROM current_way_tags
      WHERE current_way_tags.way_id = current_ways.id
    ) tags
  ) AS tag
FROM
  current_ways
  JOIN changesets
    ON current_ways.changeset_id = changesets.id
  JOIN users
    ON changesets.user_id = users.id;

-- Relations
DROP VIEW IF EXISTS api_current_relations;
CREATE VIEW api_current_relations AS
SELECT
  current_relations.id as id,
  current_relations.visible as visible,
  current_relations.version as version,
  current_relations.changeset_id as changeset,
  current_relations.timestamp AT TIME ZONE 'UTC' as timestamp,
  users.display_name as user,
  changesets.user_id as uid,
  (SELECT json_agg(members) FROM (
    SELECT
      lower(member_type::text) as type,
      member_id as ref, 
      member_role as role
    FROM
      relation_members 
    WHERE
      relation_id = current_relations.id
  ) members) as member,
  (SELECT json_agg(tags) FROM (
    SELECT
      k,
      v
    FROM
      current_relation_tags
    WHERE
      current_relation_tags.relation_id = current_relations.id
  ) tags) as tag
FROM
  current_relations
  JOIN changesets
    ON current_relations.changeset_id = changesets.id
    JOIN users
      ON changesets.user_id = users.id;
-- functions
-- func_getBbox.sql
CREATE OR REPLACE FUNCTION getBbox (numeric, numeric, numeric, numeric) RETURNS osmMap AS $getBbox$
  DECLARE
    v_minLat ALIAS FOR $1;
    v_minLon ALIAS FOR $2;
    v_maxLat ALIAS FOR $3;
    v_maxLon ALIAS FOR $4;
    v_bounds json;
    v_nodes json;
    v_ways json;
    v_relations json;
  BEGIN
    CREATE LOCAL TEMP TABLE nodes_in_bbox ON COMMIT DROP AS
    SELECT DISTINCT
      current_nodes.id as node_id
    FROM
      current_nodes
    WHERE
      current_nodes.latitude > v_minLat * 10000000
      AND current_nodes.longitude > v_minLon * 10000000
      AND current_nodes.latitude < v_maxLat * 10000000
      AND current_nodes.longitude < v_maxLon * 10000000;

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

    RETURN (v_bounds, v_nodes, v_ways, v_relations);

  END;
$getBbox$ LANGUAGE plpgsql;
-- func_upsert_node.sql
CREATE OR REPLACE FUNCTION upsert_node(
  bigint,
  integer,
  integer,
  bigint,
  boolean,
  json
) RETURNS diffResult AS $upsert_node$
  DECLARE
    v_id ALIAS FOR $1;
    v_lat ALIAS FOR $2;
    v_lon ALIAS FOR $3;
    v_changeset ALIAS FOR $4;
    v_visible ALIAS FOR $5;
    v_tags ALIAS FOR $6;
    v_timestamp timestamp without time zone;
    v_tile bigint;
    v_redaction integer;
    v_new_id bigint;
    v_new_version bigint;
    BEGIN
      -- Set some values
        v_timestamp := now();
        v_tile := tile_for_point(v_lat, v_lon);

      -- Determine if there needs to be a new node and new verison
    SELECT
      COALESCE((
        SELECT
          node_id
        FROM
          nodes
        WHERE
          node_id = v_id
        LIMIT 1
      ), (
        SELECT
          nextval('node_id_seq')
      )) AS new_id,
      COALESCE((
        SELECT
          MAX(version)
        FROM
          nodes
        WHERE
          node_id = v_id
        GROUP BY
          node_id
        ), 0)
        +1 AS new_version
    INTO
      v_new_id,
      v_new_version;

  -- Delete the current nodes and tags
    DELETE from current_way_nodes where way_id IN (SELECT way_id from current_way_nodes WHERE node_id = v_new_id) and node_id  = v_new_id;
    DELETE from current_node_tags where node_id = v_new_id;
    DELETE from current_nodes where id = v_new_id;

    INSERT INTO
      nodes (
        node_id,
        latitude,
        longitude,
        changeset_id,
        visible,
        timestamp,
        tile,
        version
      ) VALUES (
        v_new_id,
        v_lat,
        v_lon,
        v_changeset,
        v_visible,
        v_timestamp,
        v_tile,
        v_new_version
      );    
    INSERT INTO
      current_nodes (
        id,
        latitude,
        longitude,
        changeset_id,
        visible,
        timestamp,
        tile,
        version
      ) VALUES (
        v_new_id,
        v_lat,
        v_lon,
        v_changeset,
        v_visible,
        v_timestamp,
        v_tile,
        v_new_version
      );

    -- Tags
    INSERT INTO
      node_tags (
      SELECT
        v_new_id AS node_id,
        v_new_version AS version,
        k,
        v
      FROM
        json_populate_recordset(
          null::node_tags,
          v_tags
        )
      );
    INSERT INTO
      current_node_tags (
      SELECT
        v_new_id AS node_id,
        k,
        v
      FROM
        json_populate_recordset(
          null::current_node_tags,
          v_tags
        )
      );
    INSERT INTO
      current_way_nodes (
      SELECT
        way_id,
        node_id,
        sequence_id
      FROM
        way_nodes
      WHERE
        way_id IN (SELECT way_id from way_nodes WHERE node_id = v_new_id) AND
        version = (
          SELECT
            MAX(version)
          FROM
            way_nodes
          WHERE
            way_id IN (SELECT way_id from way_nodes WHERE node_id = v_new_id)
        ) AND
        node_id = v_new_id
      );

    RETURN (v_id, v_new_id, v_new_version);
    END;
$upsert_node$ LANGUAGE plpgsql;
-- func_upsert_relation.sql
CREATE OR REPLACE FUNCTION upsert_relation(
  bigint,
  integer,
  boolean,
  json,
  json
) RETURNS diffResult AS $upsert_relation$
  DECLARE
    v_id ALIAS FOR $1;
    v_changeset ALIAS FOR $2;
    v_visible ALIAS FOR $3;
    v_members ALIAS FOR $4;
    v_tags ALIAS FOR $5;
    v_timestamp timestamp without time zone;
    v_redaction_id integer;
    v_new_id bigint;
    v_new_version bigint;
  BEGIN
    -- Set some values
      v_timestamp := now();

    -- Determine if there needs to be a new relation and new verison
    SELECT
      COALESCE((
        SELECT
          relation_id
        FROM
          relations
        WHERE
          relation_id = v_id
        LIMIT 1
      ), (
        SELECT
          nextval('relation_id_seq')
      )) AS new_id,
      COALESCE((
        SELECT
          MAX(version)
        FROM
          relations
        WHERE
          relation_id = v_id
        GROUP BY
          relation_id
        ), 0)
        +1 AS new_version
    INTO
      v_new_id,
      v_new_version;

  -- Delete the current way nodes and tags
    DELETE from current_relation_tags where relation_id = v_new_id;
    DELETE from current_relation_members where relation_id = v_new_id;
    DELETE from current_relations where id = v_new_id;

    INSERT INTO
      relations (
        relation_id,
        changeset_id,
        timestamp,
        version,
        visible,
        redaction_id
      ) VALUES (
        v_new_id,
        v_changeset,
        v_timestamp,
        v_new_version,
        v_visible,
        v_redaction_id
      );    
    INSERT INTO
      current_relations (
        id,
        changeset_id,
        timestamp,
        visible,
        version
      ) VALUES (
        v_new_id,
        v_changeset,
        v_timestamp,
        v_visible,
        v_new_version
      );  

    -- Tags
    INSERT INTO
      relation_tags (
      SELECT
        v_new_id AS relation_id,
        k,
        v,
        v_new_version AS version
      FROM
        json_populate_recordset(
          null::relation_tags,
          v_tags
        )
      );
    INSERT INTO
      current_relation_tags (
      SELECT
        v_new_id AS relation_id,
        k,
        v
      FROM
        json_populate_recordset(
          null::current_relation_tags,
          v_tags
        )
      );

      -- Associated Members
      INSERT INTO
       relation_members (
       SELECT
         v_new_id AS relation_id,
         member_type as member_type,
         member_id as member_id,
         member_role as member_role,
         v_new_version AS version,
         sequence_id as sequence_id
       FROM
         json_populate_recordset(
           null::relation_members,
           v_members
         )
       );

      INSERT INTO
       current_relation_members (
       SELECT
         v_new_id AS relation_id,
         member_type as member_type,
         member_id as member_id,
         member_role as member_role,
         sequence_id as sequence_id
       FROM
         json_populate_recordset(
           null::current_relation_members,
           v_members
         )
       );

    RETURN (v_id, v_new_id, v_new_version);
    END;
$upsert_relation$ LANGUAGE plpgsql;
