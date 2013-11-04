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

-- node update/insert function
DROP TYPE IF EXISTS diffResult CASCADE;
CREATE TYPE diffResult AS (old_id bigint, new_id bigint, new_version bigint);

CREATE OR REPLACE FUNCTION upsert_node(
  bigint,
  integer,
  integer,
  bigint,
  json
) RETURNS diffResult AS $upsert_node$
  DECLARE
    v_id ALIAS FOR $1;
    v_lat ALIAS FOR $2;
    v_lon ALIAS FOR $3;
    v_changeset ALIAS FOR $4;
    v_tags ALIAS FOR $5;
    v_visible boolean;
    v_timestamp timestamp without time zone;
    v_tile bigint;
    v_redaction integer;
    v_new_id bigint;
    v_new_version bigint;
    BEGIN
      -- Set some values
        v_visible := true;
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

    RETURN (v_id, v_new_id, v_new_version);
    END;
$upsert_node$ LANGUAGE plpgsql;

-- ways
CREATE OR REPLACE FUNCTION upsert_way(
  bigint,
  integer,
  boolean,
  json,
  json
) RETURNS diffResult AS $upsert_way$
  DECLARE
    v_id ALIAS FOR $1;
    v_changeset ALIAS FOR $2;
    v_visible ALIAS FOR $3;
    v_nodes ALIAS FOR $4;
    v_tags ALIAS FOR $5;
    v_timestamp timestamp without time zone;
    v_tile bigint;
    v_redaction_id integer;
    v_new_id bigint;
    v_new_version bigint;
  BEGIN
    -- Set some values
      v_timestamp := now();
    -- Determine if there needs to be a new node and new verison
    SELECT
      COALESCE((
        SELECT
          way_id
        FROM
          ways
        WHERE
          way_id = v_id
        LIMIT 1
      ), (
        SELECT
          nextval('way_id_seq')
      )) AS new_id,
      COALESCE((
        SELECT
          MAX(version)
        FROM
          ways
        WHERE
          way_id = v_id
        GROUP BY
          way_id
        ), 0)
        +1 AS new_version
    INTO
      v_new_id,
      v_new_version;

  -- Delete the current way nodes and tags
    DELETE from current_way_tags where way_id = v_new_id;
    DELETE from current_way_nodes where way_id = v_new_id;
    DELETE from current_ways where id = v_new_id;

    INSERT INTO
      ways (
        way_id,
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
      current_ways (
        id,
        changeset_id,
        timestamp,
        version,
        visible
      ) VALUES (
        v_new_id,
        v_changeset,
        v_timestamp,
        v_new_version,
        v_visible
      );  

    -- Tags
    INSERT INTO
      way_tags (
      SELECT
        v_new_id AS way_id,
        k,
        v,
        v_new_version AS version
      FROM
        json_populate_recordset(
          null::way_tags,
          v_tags
        )
      );
    INSERT INTO
      current_way_tags (
      SELECT
        v_new_id AS way_id,
        k,
        v
      FROM
        json_populate_recordset(
          null::current_way_tags,
          v_tags
        )
      );

      -- Associated Nodes
      INSERT INTO
       way_nodes (
       SELECT
         v_new_id AS way_id,
         node_id as node_id,
         v_new_version AS version,
         sequence_id as sequence_id
       FROM
         json_populate_recordset(
           null::way_nodes,
           v_nodes
         )
       );
      INSERT INTO
       current_way_nodes (
       SELECT
         v_new_id AS way_id,
         node_id as node_id,
         sequence_id as sequence_id
       FROM
         json_populate_recordset(
           null::way_nodes,
           v_nodes
         )
       );

    RETURN (v_id, v_new_id, v_new_version);
    END;
$upsert_way$ LANGUAGE plpgsql;

-- Relations
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
