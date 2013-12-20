DROP TABLE sessions;
CREATE TABLE sessions
(
  created_time timestamp,
  request_token varchar(255),
  request_token_secret varchar(255),
  access_token varchar(255),
  access_token_secret varchar(255),
  user_id bigint,
  user_data json
);
