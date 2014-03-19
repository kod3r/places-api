-- These are functions used to clean up the data

-- Add uuids (you can only run this once!)
INSERT INTO node_tags
SELECT node_id as node_id, max(version) as version, 'nps:places_uuid' as k, uuid_generate_v4() as v from nodes group by node_id;
