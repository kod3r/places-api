--DROP FUNCTION new_session(text, text);
CREATE OR REPLACE FUNCTION new_session(
  text,
  text
) RETURNS text AS $new_session$
  DECLARE
    v_token ALIAS FOR $1;
    v_secret ALIAS FOR $2;
    BEGIN

    INSERT INTO
      sessions
    (
      created_time,
      request_token,
      request_token_secret
    ) VALUES (
      now() AT TIME ZONE 'UTC',
      v_token,
      v_secret
    );

    RETURN v_secret;
  END;
$new_session$ LANGUAGE plpgsql;
