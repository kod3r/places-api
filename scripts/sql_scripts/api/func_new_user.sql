--DROP FUNCTION new_user(text, text, text, text, bigint, text, text, text, double precision, double precision, smallint, text, boolean, integer, integer);
CREATE OR REPLACE FUNCTION new_user(
  text,
  text,
  text,
  text,
  bigint,
  text,
  text,
  text,
  double precision,
  double precision,
  smallint,
  text,
  boolean,
  integer,
  integer
) RETURNS json AS $new_user$
  DECLARE
    v_token ALIAS FOR $1;
    v_secret ALIAS FOR $2;
    v_access_token ALIAS FOR $3;
    v_access_secret ALIAS FOR $4;
    v_id ALIAS FOR $5;
    v_account_created ALIAS FOR $6;
    v_display_name ALIAS FOR $7;
    v_description ALIAS FOR $8;
    v_home_lat ALIAS FOR $9;
    v_home_lon ALIAS FOR $10;
    v_home_zoom ALIAS FOR $11;
    v_avatar_url ALIAS FOR $12;
    v_pd ALIAS FOR $13;
    v_changesets ALIAS FOR $14;
    v_traces ALIAS FOR $15;
    v_return_json json;
    v_user_count smallint;
    v_user_name_count smallint;
    v_res boolean;
    BEGIN

    -- First we need to update the users table
    SELECT
      count(*)
    FROM
      users
    WHERE
      description = v_description
    INTO
      v_user_count;

    SELECT
      count(*)
    FROM
      users
    WHERE
      display_name = v_display_name AND
      description != v_description
    INTO
      v_user_name_count;

    IF v_user_name_count > 0 THEN
      -- This user is already in the system, with a different account number
      v_display_name = v_display_name || '_nps';
    END IF;

    -- if the user doesn't exist, add it
    IF v_user_count < 1 THEN

      INSERT INTO
        users
      (
        email,
        id,
        pass_crypt,
        creation_time,
        display_name,
        data_public,
        description,
        home_lat,
        home_lon,
        home_zoom,
        pass_salt,
        image_file_name,
        consider_pd,
        changesets_count,
        traces_count
      ) VALUES (
        v_id || '@example.com',
        v_id,
        '0',
        to_timestamp(v_account_created, 'YYYY-MM-DD HH24:MI:SS'),
        v_display_name,
        true,
        v_description,
        v_home_lat,
        v_home_lon,
        v_home_zoom,
        '0',
        v_avatar_url,
        v_pd,
        v_changesets,
        v_traces
      );
    ELSE

    -- OTHERWISE UPDATE IT!
    UPDATE
      users
    SET
      email = v_id || '@example.com',
      pass_crypt = 0,
      creation_time = to_timestamp(v_account_created, 'YYYY-MM-DD HH24:MI:SS'),
      display_name = v_display_name,
      data_public = true,
      description  = v_description,
      home_lat = v_home_lat,
      home_lon = v_home_lon,
      home_zoom = v_home_zoom,
      pass_salt = 0,
      image_file_name = v_avatar_url,
      consider_pd = v_pd,
      changesets_count = v_changesets,
      traces_count= v_traces
    WHERE
      id = v_id;
    END IF;

    -- UPDATE THE SESSION TABLE
    UPDATE
      sessions
    SET
      access_token = v_access_token,
      access_token_secret = v_access_secret,
      user_id = v_id
    WHERE
      request_token = v_token AND
      request_token_secret = v_secret;


    SELECT json_agg(session) as session FROM (
      SELECT
        *
      FROM
        sessions
      WHERE
        request_token = v_token AND
        request_token_secret = v_secret
    ) session into v_return_json;

    -- Update the pgsnapshot view
    SELECT res FROM nps_dblink_pgs('select * from pgs_new_user(' || quote_literal(v_id) || ', ' || quote_literal(v_display_name) || ')') as res into v_res;

    RETURN v_return_json;
  END;
$new_user$ LANGUAGE plpgsql;
