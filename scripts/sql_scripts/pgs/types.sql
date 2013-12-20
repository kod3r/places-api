DROP TYPE IF EXISTS new_hstore CASCADE;
CREATE TYPE new_hstore AS (k text, v text);

DROP TYPE IF EXISTS new_relation_members CASCADE;
CREATE TYPE new_relation_members AS (relation_id bigint, member_id bigint, member_type text, member_role text, sequence_id integer);
