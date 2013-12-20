-- Type for map bbox return
DROP TYPE IF EXISTS osmMap CASCADE;
CREATE TYPE osmMap AS (bounds json, node json, way json, relation json, limits json);

-- node update/insert function
DROP TYPE IF EXISTS diffResult CASCADE;
CREATE TYPE diffResult AS (old_id bigint, new_id bigint, new_version bigint);


