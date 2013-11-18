/* jshint camelcase: false */
var config = require('../../config'),
xmlJs = require('xmljs_translator'),
database = require('../database'),
oauth = require('oauth'),
extras = {
  osmOauth: new oauth.OAuth(
    'http://' + config.oauth.server + '/oauth/request_token',
    'http://' + config.oauth.server + '/oauth/access_token',
    config.oauth.consumerKey,
    config.oauth.consumerSecret,
    '1.0',
    null,
    'HMAC-SHA1'
  ),
  splitAuthHeader: function(authorization) {
    // must find a better way to do this
    var auths = authorization.split(' '),
    authObj = {}, authIndex;
    for (authIndex in auths) {
      if (auths[authIndex].indexOf('=') >= 0) {
        authObj[auths[authIndex].split('=')[0]] = auths[authIndex].split('=')[1].replace(/\"/g, '').replace(/,/g, '');
      }
    }
    return authObj;
  },
  addRequestToken: function (token, tokenSecret, callback) {
    var query = 'SELECT new_session(\'{{token}}\', \'{{tokenSecret}}\')';
    query = database().addParams(query, 'addToken', {'token': token, 'tokenSecret': tokenSecret});
    database().query(query, null, function() {
      callback();
    });
  },
  getTokenSecret: function(token, callback) {
    var query = 'SELECT request_token_secret FROM sessions WHERE request_token = \'{{token}}\'';
    query = database().addParams(query, 'tokens', {'token': token});
    database().query(query, null, function(_, queryRes) {
      if (queryRes && queryRes.data && queryRes.data.tokens && queryRes.data.tokens[0] && queryRes.data.tokens[0].request_token_secret) {
        callback(queryRes.data.tokens[0].request_token_secret);
      } else {
        callback(null);
      }
    });
  },
  getUserInfo: function(requestToken, requestTokenSecret, oauthAccessToken, oauthAccessTokenSecret, callback) {

    // First Check in the database for the user info
    var query = 'SELECT get_user(\'{{token}}\', \'{{token_secret}}\')';
    query = database().addParams(query, 'user', {'token': requestToken, 'token_secret': requestTokenSecret});
    database().query(query, null, function(_, queryRes) {
      console.log('-=-', JSON.stringify(queryRes));
      if (queryRes && queryRes.data && queryRes.data.user && queryRes.data.user[0] && queryRes.data.user[0].id) {
        console.log('---', queryRes);
        callback(queryRes.data.user[0].display_name, queryRes.data.user[0].id);
      } else {
        // If there is nothing, then go out to the server and get that information, and add it back to the server
        extras.osmOauth.get(
          'http://' + config.oauth.server + '/api/0.6/user/details',
          oauthAccessToken,
          oauthAccessTokenSecret,
          function (e, data){
            var jsonData = xmlJs.jsonify(data).osm.user;
            var newUserQuery = 'SELECT new_user(\'{{token}}\', \'{{token_secret}}\', \'{{access_token}}\', \'{{access_token_secret}}\', \'{{id}}\', \'{{creation_time}}\', \'{{display_name}}\', \'{{description}}\', \'{{home_lat}}\', \'{{home_lon}}\', \'{{home_zoom}}\', \'{{image_file_name}}\', \'{{consider_pd}}\', \'{{changesets_count}}\', \'{{traces_count}}\')';
            // This won't work right away, make sure we can clean it up!
            jsonData.home = jsonData.home ? jsonData.home : {'lat': '38.893889', 'lon': '-77.0425', 'zoom': '3'};
            var params = {
              'token': requestToken,
              'token_secret': requestTokenSecret,
              'access_token': oauthAccessToken,
              'access_token_secret': oauthAccessTokenSecret,
              'id': jsonData.id,
              'creation_time': jsonData.account_created,
              'display_name': jsonData.display_name,
              'description': JSON.stringify(jsonData.description),
              'home_lat': jsonData.home.lat,
              'home_lon': jsonData.home.lon,
              'home_zoom': jsonData.home.zoom,
              'image_file_name': jsonData.img.href,
              'consider_pd': jsonData['contributor-terms'].pd,
              'changesets_count': jsonData.changesets.count,
              'traces_count': jsonData.traces.count
            };
            newUserQuery = database().addParams(newUserQuery, 'user', params);
            database().query(newUserQuery, null, function(a, b) {
              console.log('a', a, 'b', b);
              callback(jsonData.display_name, jsonData.id);
            });
          });
      }
    });
  }
};
exports = module.exports = {
  accessToken: function (auth, callback) {
    var auths = extras.splitAuthHeader(auth);
    extras.getTokenSecret(auths.oauth_token, function(tokenSecret) {
      extras.osmOauth.getOAuthAccessToken(auths.oauth_token, tokenSecret, function (error, oauthAccessToken, oauthAccessTokenSecret) {
        if (error) {
          callback(error);
        } else {
          // Get the user info
          extras.getUserInfo(auths.oauth_token, tokenSecret, oauthAccessToken, oauthAccessTokenSecret, function(e, username, userId) {
            callback(error, oauthAccessToken, oauthAccessTokenSecret, username, userId);
          });
        }
      });
    });
  },
  requestToken: function(callback){
    extras.osmOauth.getOAuthRequestToken(function(error, token, tokenSecret) {
      extras.addRequestToken(token, tokenSecret, function() {
        callback(error, token, tokenSecret);
      });
    });
  },
  authorize: function (req, res) {
    res.redirect('http://' + config.oauth.server + req.originalUrl);
  }
};
