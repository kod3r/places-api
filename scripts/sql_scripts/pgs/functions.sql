-- Function: public.pgs_update_changeset(bigint)

-- DROP FUNCTION public.pgs_update_changeset(bigint);

CREATE OR REPLACE FUNCTION public.pgs_update_changeset(bigint)
  RETURNS bigint AS
$BODY$
  DECLARE
    v_changeset_id ALIAS for $1;
    v_changes bigint;
  BEGIN
  
    SELECT count(*) FROM (
    SELECT pgs_upsert_node(id, lat, lon, changeset, visible, timestamp, tag, version, uid) FROM api_nodes WHERE changeset = v_changeset_id
    UNION ALL
    SELECT pgs_upsert_way(id, changeset, visible, timestamp, nd, tag, version, uid) FROM api_ways WHERE changeset = v_changeset_id
    UNION ALL
    SELECT pgs_upsert_relation(id, changeset, visible, member, tag, timestamp, version, uid) FROM api_relations WHERE changeset = v_changeset_id)
    changes INTO v_changes;

    -- Update the users
    INSERT INTO users SELECT id, display_name AS name FROM api_users WHERE id NOT IN (SELECT id FROM users);

    RETURN v_changes;
    END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- Render Functions
--DROP FUNCTION pgs_upsert_node(bigint, double precision, double precision, bigint, boolean, timestamp without time zone, json, bigint, bigint);
CREATE OR REPLACE FUNCTION pgs_upsert_node(
  bigint,
  double precision,
  double precision,
  bigint,
  boolean,
  timestamp without time zone,
  json,
  bigint,
  bigint
) RETURNS boolean AS $pgs_upsert_node$
  DECLARE
    v_id ALIAS FOR $1;
    v_lat ALIAS FOR $2;
    v_lon ALIAS FOR $3;
    v_changeset ALIAS FOR $4;
    v_visible ALIAS FOR $5;
    v_timestamp ALIAS FOR $6;
    v_tags ALIAS FOR $7;
    v_version ALIAS FOR $8;
    v_userid ALIAS FOR $9;
    v_X boolean;
    BEGIN
  -- Delete the current nodes and tags
    DELETE from nodes where id = v_id;

    IF v_visible THEN
      INSERT INTO
        nodes (
          id,
          version,
          user_id,
          tstamp,
          changeset_id,
          tags,
          geom
        ) VALUES (
          v_id,
          v_version,
          v_userid,
          v_timestamp,
          v_changeset,
          (select hstore(array_agg(k), array_agg(v)) from json_populate_recordset(null::new_hstore,v_tags)),
          ST_SetSRID(ST_MakePoint(v_lon, v_lat),4326)
        );
    END IF;
    
    SELECT true into v_X; --TODO these should be more useful

    RETURN v_X;
    END;
$pgs_upsert_node$ LANGUAGE plpgsql;


-- ----------------------------------------
--DROP FUNCTION pgs_upsert_way(bigint, bigint, boolean, timestamp without time zone, json, json, bigint, bigint);
CREATE OR REPLACE FUNCTION pgs_upsert_way(
  bigint,
  bigint,
  boolean,
  timestamp without time zone,
  json,
  json,
  bigint,
  bigint
) RETURNS boolean AS $pgs_upsert_way$
  DECLARE
    v_id ALIAS FOR $1;
    v_changeset ALIAS FOR $2;
    v_visible ALIAS FOR $3;
    v_timestamp ALIAS FOR $4;
    v_nodes ALIAS FOR $5;
    v_tags ALIAS FOR $6;
    v_version ALIAS FOR $7;
    v_user_id ALIAS FOR $8;
    v_X boolean;
  BEGIN 

  -- Delete the current way nodes and tags
    DELETE from way_nodes where way_id = v_id;
    DELETE from ways where id = v_id;

    IF v_visible THEN
      INSERT INTO
        ways (
          id,
          version,
          user_id,
          tstamp,
          changeset_id,
          tags,
          nodes
        ) VALUES (
          v_id,
          v_version,
          v_user_id,
          v_timestamp,
          v_changeset,
          (select hstore(array_agg(k), array_agg(v)) from json_populate_recordset(null::new_hstore,v_tags)),
          (SELECT array_agg(node_id) FROM json_populate_recordset(null::way_nodes, v_nodes))
        );    
    
        -- Associated Nodes
        INSERT INTO
         way_nodes (
         SELECT
           v_id AS way_id,
           node_id as node_id,
           sequence_id as sequence_id
         FROM
           json_populate_recordset(
             null::way_nodes,
             v_nodes
           )
         );
      END IF;
      
    SELECT true into v_X; --TODO these should be more useful

    RETURN v_X;
    END;
$pgs_upsert_way$ LANGUAGE plpgsql;

-- ------------------------------------------
--DROP FUNCTION pgs_upsert_relation(bigint, bigint, boolean, json, json, timestamp without time zone, bigint, bigint);
CREATE OR REPLACE FUNCTION pgs_upsert_relation(
  bigint,
  bigint,
  boolean,
  json,
  json,
  timestamp without time zone,
  bigint,
  bigint
) RETURNS boolean AS $pgs_upsert_relation$
  DECLARE
    v_id ALIAS FOR $1;
    v_changeset ALIAS FOR $2;
    v_visible ALIAS FOR $3;
    v_members ALIAS FOR $4;
    v_tags ALIAS FOR $5;
    v_timestamp ALIAS FOR $6;
    v_version ALIAS FOR $7;
    v_user_id ALIAS FOR $8;
    v_X boolean;
  BEGIN

  -- Delete the current way nodes and tags
    DELETE from relation_members where relation_id = v_id;
    DELETE from relations where id = v_id;

    IF v_visible THEN
      INSERT INTO
        relations (
          id,
          version,
          user_id,
          tstamp,
          changeset_id,
          tags
        ) VALUES (
          v_id,
          v_version,
          v_user_id,
          v_timestamp,
          v_changeset,
          (select hstore(array_agg(k), array_agg(v)) from json_populate_recordset(null::new_hstore,v_tags))
        );    

      -- Associated Members
      INSERT INTO
        relation_members (
          SELECT
             v_id AS relation_id,
             member_id as member_id,
             member_type::character(1) as member_type,
             member_role as member_role,
             sequence_id as sequence_id
        FROM
           json_populate_recordset(
           null::new_relation_members,
           v_members
         )
        );
    END IF;
    
    SELECT true into v_X; --TODO these should be more useful

    RETURN v_X;
    END;
$pgs_upsert_relation$ LANGUAGE plpgsql;

-- ----------------------------
--DROP FUNCTION pgs_new_user(bigint, text);
CREATE OR REPLACE FUNCTION pgs_new_user(
  bigint,
  text
) RETURNS boolean AS $pgs_new_user$
  DECLARE
    v_id ALIAS FOR $1;
    v_display_name ALIAS FOR $2;
    v_user_count bigint;
    v_user_name_count bigint;
    BEGIN

    -- First we need to update the users table
    SELECT
      count(*)
    FROM
      users
    WHERE
      id = v_id
    INTO
      v_user_count;

    SELECT
      count(*)
    FROM
      users
    WHERE
      name = v_display_name AND
      id != v_id
    INTO
      v_user_name_count;

    -- if the user doesn't exist, add it
    IF v_user_count < 1 THEN

      INSERT INTO
        users
      (
        id,
        name
      ) VALUES (
        v_id,
        v_display_name
      );
    END IF;

    RETURN true;
  END;
$pgs_new_user$ LANGUAGE plpgsql;
