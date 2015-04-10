## How to connect to Places with JOSM

###\#1 Get a session key from the database

```sql
SELECT
  access_token AS "Access Token Key",
  access_token_secret AS "Access Token Secret",
  users.display_name AS "User Name"
FROM
  sessions JOIN users ON sessions.user_id = users.id 
WHERE
  users.display_name LIKE '%YOUR LAST NAME%'
ORDER BY
  sessions.created_time DESC LIMIT 1;
```

###\#2 Prevent that session key from expiring

```sql
UPDATE
  sessions
SET
  created_time = '3000-01-01 00:00:00'
WHERE
  access_token = 'ACCESS TOKEN KEY FROM FIRST STEP';
```

###\#3 Download JOSM
You can download JOSM from [this link](https://josm.openstreetmap.de/wiki/Download).

###\#4 Open JOSM and navigate to "Connection Settings"
1. JOSM -> Preferences
2. Click the "World" button (should be 2nd from the top in the left)

###\#5 Change the OSM Server URL
1. The Places server URL is: `http://10.147.153.193/api`

The validate button doesn't work with Places.

###\#6 Create a new Access Token
1. Click the `New Acces Token` button
2. From the `Please select an authorization procedure` dropdown, select `Manual`
3. Next to `Access Token Key`, enter the access token key from your query in step one
4. Next to `Access Token Secret`, enter the access token secret from your query in step one
5. Make sure the `Save Access Token in preferences` checkbox is checked
6. Click `Test Access Token`, your username should be displayed
7. If that works, click the `Accept Access Token` button
8. Press `Ok` on the Preferences screen, and you are read to start editing Places with JOSM

###\#7 TODO: JOSM Tutorial 
In the meantime, there are some great JOSM tutorials online.

The most up-to-date guide is usually: [The OpenStreetMap Wiki JOSM Guide](http://wiki.openstreetmap.org/wiki/JOSM/Guide).
