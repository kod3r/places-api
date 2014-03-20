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
    BEGIN

    IF v_object = 'node' THEN
    
      FOR v_row IN SELECT id, lat*10000000 as lat, lon*10000000 as lon, changeset, visible, timestamp, tag, version, "uid" FROM api_current_nodes LOOP
        SELECT res FROM dblink('dbname=poi_pgs', 'select * from pgs_upsert_node(' || quote_literal(v_row.id) || ', ' || quote_literal(v_row.lat) || ', ' || quote_literal(v_row.lon) || ', ' || quote_literal(v_row.changeset) || ', ' || quote_literal(v_row.visible) || ', ' || quote_literal(v_row.timestamp) || ', ' || quote_literal(v_row.tag) || ', ' || quote_literal(v_row.version) || ', ' || quote_literal(v_row.uid) || ')') as pgs(res boolean) into v_res; 
      END LOOP;  

    ELSIF v_object = 'way' THEN
      FOR v_row IN SELECT id, changeset, visible, timestamp, nd as nodes, version, uid as user_id FROM api_current_ways LOOP
        SELECT res FROM dblink('dbname=poi_pgs', 'select * from pgs_upsert_way(' || quote_literal(v_row.id) || ', ' || quote_literal(v_row.changeset) || ', ' || quote_literal(v_row.visible) || ', ' || quote_literal(v_row.timestamp) || ', ' || quote_literal(v_row.nodes) || ', ' || quote_literal(v_row.tags) || ', ' || quote_literal(v_row.version) || ', ' || quote_literal(v_row.user_id) || ')') as pgs(res boolean) into v_res;
      END LOOP; 
    
    ELSIF v_object = 'relation' THEN
      FOR v_row IN SELECT id, changeset, visible, member as members, tag as tags, timestamp, version, uid as user_id FROM api_current_relations LOOP
        SELECT res FROM dblink('dbname=poi_pgs', 'select * from pgs_upsert_relation(' || quote_literal(v_row.id) || ', ' || quote_literal(v_row.changeset) || ', ' || quote_literal(v_row.visible) || ', ' || quote_literal(v_row.members) || ', ' || quote_literal(v_row.tags) || ', ' || quote_literal(v_row.timestamp) || ', '  || quote_literal(v_row.version) || ', ' || quote_literal(v_row.user_id) || ')') as pgs(res boolean) into v_res;
      END LOOP; 
  
    END IF;

    RETURN v_res;
  END;
$api_update_object$ LANGUAGE plpgsql;