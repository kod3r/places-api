-- These are functions used to clean up the data

-- Add uuids (you can only run this once!)
INSERT INTO node_tags
SELECT node_id as node_id, max(version) as version, 'nps:places_uuid' as k, uuid_generate_v4() as v from nodes group by node_id;

-- Update all objects
CREATE OR REPLACE FUNCTION api_update_object(
  text
) RETURNS boolean AS $api_update_object$
  DECLARE
    v_object ALIAS FOR $1;
    v_res boolean;
    v_row record;
    v_refs json;
    BEGIN

    -- NODE
    IF v_object = 'node' THEN
      FOR v_row IN SELECT id, lat*10000000 as lat, lon*10000000 as lon, changeset, visible, timestamp, tag, version, "uid" FROM api_current_nodes LOOP
        SELECT res FROM dblink('dbname=poi_pgs', 'select * from pgs_upsert_node(' || quote_literal(v_row.id) || ', ' || quote_literal(v_row.lat) || ', ' || quote_literal(v_row.lon) || ', ' || quote_literal(v_row.changeset) || ', ' || quote_literal(v_row.visible) || ', ' || quote_literal(v_row.timestamp) || ', ' || quote_literal(v_row.tag) || ', ' || quote_literal(v_row.version) || ', ' || quote_literal(v_row.uid) || ')') as pgs(res boolean) into v_res; 
      END LOOP;  

    -- WAY
    ELSIF v_object = 'way' THEN
      FOR v_row IN SELECT id, changeset, visible, timestamp, nd as nodes, tag as tags, version, uid as user_id FROM api_current_ways LOOP
        SELECT
          to_json(array_agg(way_nodes))
        FROM (
          SELECT
            node_id,
            way_id,
            sequence_id
          FROM
            current_way_nodes
          WHERE
            way_id = v_row.id AND
            node_id IN (
              SELECT ((json_array_elements(v_row.nodes))->'ref')::text::bigint)
            ) way_nodes INTO v_refs;
        SELECT res FROM dblink('dbname=poi_pgs', 'select * from pgs_upsert_way(' || quote_literal(v_row.id) || ', ' || quote_literal(v_row.changeset) || ', ' || quote_literal(v_row.visible) || ', ' || quote_literal(v_row.timestamp) || ', ' || quote_literal(v_refs) || ', ' || quote_literal(v_row.tags) || ', ' || quote_literal(v_row.version) || ', ' || quote_literal(v_row.user_id) || ')') as pgs(res boolean) into v_res;
      END LOOP; 
    
    -- RELATION
    ELSIF v_object = 'relation' THEN
      FOR v_row IN SELECT id, changeset, visible, member as members, tag as tags, timestamp, version, uid as user_id FROM api_current_relations LOOP
        SELECT
            to_json(array_agg(current_relations))
          FROM (
            SELECT
              v_row.id as relation_id,
              ((json_array_elements(v_row.members))->>'ref')::text::bigint as member_id,
              ((json_array_elements(v_row.members))->>'type') as member_type,
              ((json_array_elements(v_row.members))->>'role') as member_role
          ) current_relations INTO v_refs;
        SELECT res FROM dblink('dbname=poi_pgs', 'select * from pgs_upsert_relation(' || quote_literal(v_row.id) || ', ' || quote_literal(v_row.changeset) || ', ' || quote_literal(v_row.visible) || ', ' || quote_literal(v_row.members) || ', ' || quote_literal(v_row.tags) || ', ' || quote_literal(v_row.timestamp) || ', '  || quote_literal(v_row.version) || ', ' || quote_literal(v_row.user_id) || ')') as pgs(res boolean) into v_res;
      END LOOP; 
  
    END IF;

    RETURN v_res;
  END;
$api_update_object$ LANGUAGE plpgsql;


--- Delete a changeset
--delete from changeset_tags where changeset_id = 27;
--DELETE FROM node_tags as A USING nodes B WHERE B.node_id = A.node_id and B.version = A.version and B.changeset_id = 27;
--DELETE FROM nodes where changeset_id = 27;
--DELETE FROM way_tags as A USING ways B WHERE B.way_id = A.way_id and B.version = A.version and B.changeset_id = 27;
--DELETE FROM ways where changeset_id = 27;
--DELETE FROM relation_tags as A USING relations B WHERE B.relation_id = A.relation_id and B.version = A.version and B.changeset_id = 27;
--DELETE FROM relations where changeset_id = 27;
--DELETE FROM changesets where id = 27;

-- PGS
-- delete from nodes where changeset_id = 27;
-- delete from ways_tags where changeset_id = 27; <-- won't work, but couldn't test on my dataset 
-- delete from ways where changeset_id = 27;
