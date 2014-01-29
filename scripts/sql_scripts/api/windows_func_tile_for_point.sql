-- Function: tile_for_point(integer, integer)

-- DROP FUNCTION tile_for_point(integer, integer);
CREATE OR REPLACE FUNCTION tile_for_point(integer, integer)
  RETURNS bigint AS
$BODY$
  DECLARE
    v_lat ALIAS FOR $1;
    v_lon ALIAS FOR $2;
    v_lat2 double precision;
    v_lon2 double precision;
    v_lat3 bigint;
    v_lon3 bigint;
    v_tile integer;
    v_NRLEVELS integer;
    v_WORLD_PARTS integer;
    v_i integer;

  BEGIN
   v_NRLEVELS := 24;
   v_WORLD_PARTS := (1 << v_NRLEVELS);
   v_tile := 0;
   v_lat2 := v_lat / 10000000.0;
   v_lon2 := v_lon / 10000000.0;

   v_lon3 := ((v_lon2 + 180.0) * v_WORLD_PARTS / 360.0)::integer;
   v_lat3 := ((v_lon2 + 90.0) * v_WORLD_PARTS / 180.0)::integer;

   IF v_lon3 = v_WORLD_PARTS THEN
     v_lon3 := v_WORLD_PARTS - 1;
   END IF;
   IF v_lat3 = v_WORLD_PARTS THEN
     v_lat3 := v_WORLD_PARTS - 1;
   END IF;

  FOR v_i IN SELECT (v_NRLEVELS-1)-series from generate_series(0,(v_NRLEVELS-1)) as series LOOP
    v_tile := v_tile << 2;

    v_tile := v_tile | ((v_lat3 >> v_i) & 1) | ((v_lon3 >> v_i) & 1);
  END LOOP;

  return v_tile::bigint;
  /*
  long tile = 0;
  int i;
  for (i = NR_LEVELS-1; i >= 0; i--)
  {
      long xbit = ((x >> i) & 1);
      long ybit = ((y >> i) & 1);
      tile <<= 2;
      // Note that x is the MSB
      tile |= (xbit<<1) | ybit;
  }
  return tile;
  */

  END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION tile_for_point(integer, integer)
  OWNER TO postgres;
