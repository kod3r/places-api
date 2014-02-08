/* jshint camelcase: false */
var config = require('../../config'),
xmlJs = require('xmljs_trans_js'),
database = require('../database')('api'),
oauth = require('oauth'),
http = require('http'),
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
  josmOauth: new oauth.OAuth( // A bug? in JOSM won't let it use our key, this bypasses that bug
    'http://' + config.oauth.server + '/oauth/request_token',
    'http://' + config.oauth.server + '/oauth/access_token',
    'F7zPYlVCqE2BUH9Hr4SsWZSOnrKjpug1EgqkbsSb',
    'rIkjpPcBNkMQxrqzcOvOC4RRuYupYr7k8mfP13H5',
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
  getAccessSecret: function(token, callback) {
    var query = 'SELECT request_token, request_token_secret, access_token,  access_token_secret FROM sessions WHERE access_token = \'{{token}}\'';
    query = database().addParams(query, 'tokens', {'token': token});
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
    query = database().addParams(query, 'user', {'token': requestToken, 'token_secret': requestTokenSecret});
    database().query(query, null, function(_, queryRes) {
      if (queryRes && queryRes.data && queryRes.data.user && queryRes.data.user[0] && queryRes.data.user[0].id) {
        callback(queryRes.data.user[0].display_name, queryRes.data.user[0].id);
      } else {
        // If there is nothing, then go out to the server and get that information, and add it back to the server
        extras.osmOauth.get(
          'http://' + config.oauth.server + '/api/0.6/user/details',
          oauthAccessToken,
          oauthAccessTokenSecret,
          extras.addUser(tokens, callback)
        );
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
      return extras.verification.qsString(params);
    }
  },
  addUser: function (tokens, callback) {
    return function (e, data) {
      var jsonData = xmlJs.jsonify(data).osm.user;
      var newUserQuery = 'SELECT new_user(\'{{token}}\', \'{{token_secret}}\', \'{{access_token}}\', \'{{access_token_secret}}\', \'{{id}}\', \'{{creation_time}}\', \'{{display_name}}\', \'{{description}}\', \'{{home_lat}}\', \'{{home_lon}}\', \'{{home_zoom}}\', \'{{image_file_name}}\', \'{{consider_pd}}\', \'{{changesets_count}}\', \'{{traces_count}}\')';
      // This won't work right away, make sure we can clean it up!
      jsonData.home = jsonData.home ? jsonData.home : {'lat': '38.893889', 'lon': '-77.0425', 'zoom': '3'};
      var params = {
        'token': tokens.requestToken,
        'token_secret': tokens.requestTokenSecret,
        'access_token': tokens.oauthAccessToken,
        'access_token_secret': tokens.oauthAccessTokenSecret,
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
        callback(b.error, jsonData.display_name, jsonData.id);
      });
    };
  }
};
exports = module.exports = {
  authReq: function (req, callback) {
    var auths = extras.splitAuthHeader(req.headers.authorization);
    extras.getAccessSecret(auths.oauth_token, function(tokens) {
      if (tokens) {
        extras.getUserInfo(tokens.request_token, tokens.request_token_secret, auths.oauth_token, tokens.access_token_secret, function(e, username, userId) {
          // Verify the signature
          var origSig = auths.oauth_signature,
          requestedUrl = req.protocol + '://' + req.get('Host') + req.originalUrl,
          compareSig = extras.osmOauth._getSignature(req.method, requestedUrl, extras.verification.baseString(auths), tokens.access_token_secret),
          jsomCompareSig = extras.josmOauth._getSignature(req.method, requestedUrl, extras.verification.baseString(auths), tokens.access_token_secret);
          if (encodeURIComponent(compareSig) === origSig || encodeURIComponent(jsomCompareSig) === origSig) {
            callback({'valid': !e, 'userId': userId, 'username': username});
          } else {
            callback({'valid': false});
          }
        });
      } else {
        callback({'valid': false});
      }
    });
  },
  authReqBasic: function (req, callback) {
    var loginHeaders = req.headers.authorization,
    options = {
      hostname: config.oauth.server,
      path: '/api/0.6/user/details',
      port: 80,
      method: 'GET',
      headers: {
        'authorization': loginHeaders
      }
    },
    result = '',
    loginReq = http.request(options, function(loginRes) {
      loginRes.setEncoding('utf8');
      loginRes.on('data', function (chunk) {
        result += chunk;
      });
      loginRes.on('end', function() {
        var tokens = {
          'requestToken': 'hash',
          'requestTokenSecret': 'hash',
          'oauthAccessToken':'hash',
          'oauthAccessTokenSecret': 'hash'
        };
        if (result && result.substr(0,1) === '<') {
          extras.addUser(tokens, function(e, userId, username) {
            callback({'valid': true, 'userId': username, 'username': userId});
          })(null, result);
        } else {
          callback({'valid': false});
        }
      });
    });

    loginReq.on('error', function(e) {
      console.log('problem with request: ' + e.message);
      callback({'valid': false});
    });

    loginReq.end();
  },
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
