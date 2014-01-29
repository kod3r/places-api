DROP TYPE IF EXISTS new_hstore CASCADE;
CREATE TYPE new_hstore AS (k text, v text);

DROP TYPE IF EXISTS new_relation_members CASCADE;
CREATE TYPE new_relation_members AS (relation_id bigint, member_id bigint, member_type text, member_role text, sequence_id integer);

-- Type: public.aggregate_way

-- DROP TYPE public.aggregate_way;

CREATE TYPE public.aggregate_way AS
   (geom public.geometry[],
    role text[]);
ALTER TYPE public.aggregate_way
  OWNER TO postgres;
