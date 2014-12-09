/* jshint camelcase: false */
var database = require('../database')('api'),
  oauth = require('oauth'),
  oauthSettings = require('../../config').oauth,
  xmlJs = require('xmljs_trans_js'),
  tools = module.exports = {
    addUser: function(tokens, callback) {
      return function(e, data) {
        var userInformation = xmlJs.jsonify(data).osm.user;
        var newUserQuery = 'SELECT new_user(\'{{token}}\', \'{{token_secret}}\', \'{{access_token}}\', \'{{access_token_secret}}\', \'{{id}}\', \'{{creation_time}}\', \'{{display_name}}\', \'{{description}}\', \'{{home_lat}}\', \'{{home_lon}}\', \'{{home_zoom}}\', \'{{image_file_name}}\', \'{{consider_pd}}\', \'{{changesets_count}}\', \'{{traces_count}}\')';
        // This won't work right away, make sure we can clean it up!
        userInformation.home = userInformation.home ? userInformation.home : {
          'lat': '38.893889',
          'lon': '-77.0425',
          'zoom': '3'
        };
        var params = {
          'token': tokens.requestToken,
          'token_secret': tokens.requestTokenSecret,
          'access_token': tokens.oauthAccessToken,
          'access_token_secret': tokens.oauthAccessTokenSecret,
          'id': userInformation.id,
          'creation_time': userInformation.account_created,
          'display_name': userInformation.display_name,
          'description': JSON.stringify(userInformation.description),
          'home_lat': userInformation.home.lat,
          'home_lon': userInformation.home.lon,
          'home_zoom': userInformation.home.zoom,
          'image_file_name': userInformation.img.href,
          'consider_pd': userInformation['contributor-terms'].pd,
          'changesets_count': userInformation.changesets.count,
          'traces_count': userInformation.traces.count
        };
        newUserQuery = database().addParams(newUserQuery, 'user', params);
        database().query(newUserQuery, null, function(a, b) {
          callback(b.error, userInformation.display_name, userInformation.id);
        });
      };
    },
    osmOauth: new oauth.OAuth(
      'http://' + oauthSettings.server + '/oauth/request_token',
      'http://' + oauthSettings.server + '/oauth/access_token',
      oauthSettings.consumerKey,
      oauthSettings.consumerSecret,
      '1.0',
      null,
      'HMAC-SHA1'
    ),
    josmOauth: new oauth.OAuth( // A bug? in JOSM won't let it use our key, this bypasses that bug
      'http://' + oauthSettings.server + '/oauth/request_token',
      'http://' + oauthSettings.server + '/oauth/access_token',
      'F7zPYlVCqE2BUH9Hr4SsWZSOnrKjpug1EgqkbsSb',
      'rIkjpPcBNkMQxrqzcOvOC4RRuYupYr7k8mfP13H5',
      '1.0',
      null,
      'HMAC-SHA1'
    ),
    splitAuthHeader: function(authorization) {
      // must find a better way to do this
      var auths = authorization.split(' '),
        authObj = {},
        authIndex;
      for (authIndex in auths) {
        if (auths[authIndex].indexOf('=') >= 0) {
          authObj[auths[authIndex].split('=')[0]] = auths[authIndex].split('=')[1].replace(/\"/g, '').replace(/,/g, '');
        }
      }
      return authObj;
    },
    addRequestToken: function(token, tokenSecret, callback) {
      var query = 'SELECT new_session(\'{{token}}\', \'{{tokenSecret}}\')';
      query = database().addParams(query, 'addToken', {
        'token': token,
        'tokenSecret': tokenSecret
      });
      database().query(query, null, function(err) {
        callback(err, token, tokenSecret);
      });
    },
    getTokenSecret: function(token, callback) {
      var query = 'SELECT request_token_secret FROM sessions WHERE request_token = \'{{token}}\'';
      query = database().addParams(query, 'tokens', {
        'token': token
      });
      database().query(query, null, function(_, queryRes) {
        if (queryRes && queryRes.data && queryRes.data.tokens && queryRes.data.tokens[0] && queryRes.data.tokens[0].request_token_secret) {
          callback(queryRes.data.tokens[0].request_token_secret);
        } else {
          callback(null);
        }
      });
    },
    getAccessSecret: function(token, callback) {
      var query = 'SELECT request_token, request_token_secret, access_token,  access_token_secret FROM sessions WHERE access_token = \'{{token}}\'';
      query = database().addParams(query, 'tokens', {
        'token': token
      });
      database().query(query, null, function(_, queryRes) {
        if (queryRes && queryRes.data && queryRes.data.tokens && queryRes.data.tokens[0] && queryRes.data.tokens[0].access_token_secret) {
          callback({
            'request_token': queryRes.data.tokens[0].request_token,
            'request_token_secret': queryRes.data.tokens[0].request_token_secret,
            'access_token': queryRes.data.tokens[0].access_token,
            'access_token_secret': queryRes.data.tokens[0].access_token_secret
          });
        } else {
          callback(null);
        }
      });
    },
    getUserInfo: function(requestToken, requestTokenSecret, oauthAccessToken, oauthAccessTokenSecret, callback) {

      // First Check in the database for the user info
      var tokens = {
          'requestToken': requestToken,
          'requestTokenSecret': requestTokenSecret,
          'oauthAccessToken': oauthAccessToken,
          'oauthAccessTokenSecret': oauthAccessTokenSecret
        },
        query = 'SELECT get_user(\'{{token}}\', \'{{token_secret}}\')';
      query = database().addParams(query, 'user', {
        'token': requestToken,
        'token_secret': requestTokenSecret
      });
      database().query(query, null, function(_, queryRes) {
        if (queryRes && queryRes.data && queryRes.data.user && queryRes.data.user[0] && queryRes.data.user[0].id) {
          callback(null, queryRes.data.user[0].display_name, queryRes.data.user[0].id);
        } else if (oauthSettings.external) {
          // If there is nothing, then go out to the server and get that information, and add it back to the server
          tools.osmOauth.get(
            'http://' + oauthSettings.server + '/api/0.6/user/details',
            oauthAccessToken,
            oauthAccessTokenSecret,
            tools.addUser(tokens, callback)
          );
        } else {
          callback('No user found');
        }
      });
    },
    verification: {
      qsString: function(obj) {
        return Object.keys(obj).sort().map(function(key) {
          return encodeURIComponent(key) + '=' +
            encodeURIComponent(obj[key]);
        }).join('&');
      },
      baseString: function(params) {
        if (params.oauth_signature) delete params.oauth_signature;
        return tools.verification.qsString(params);
      }
    },
    uid: function(n) {
      if (n > 100) return false;
      var template = new Array(n + 1).join('x');
      var possible = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
      return template.replace(/x/g, function() {
        return possible.substr(Math.floor(Math.random() * possible.length), 1);
      });
    }
  };
