--DROP FUNCTION get_user(text, text);
CREATE OR REPLACE FUNCTION get_user(
  text,
  text
) RETURNS json AS $get_user$
  DECLARE
    v_token ALIAS FOR $1;
    v_secret ALIAS FOR $2;
    v_userInfo json;
    BEGIN

    SELECT to_json(user_info) FROM (
      SELECT
        users.display_name,
        users.id
      FROM
        users
          JOIN
       sessions ON users.id = sessions.user_id
      WHERE
        sessions.request_token = v_token AND
        sessions.request_token_secret = v_secret
    ) user_info INTO v_userInfo;

    RETURN v_userInfo;
  END;
$get_user$ LANGUAGE plpgsql;
