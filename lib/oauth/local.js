/* jshint camelcase: false */

var database = require('../database')('api'),
  tools = require('./tools');

module.exports = {
  addUser: function(adUserInformation, callback) {
    adUserInformation.oauth_token = adUserInformation.query ? adUserInformation.query.oauth_token : null;
    adUserInformation.userIdQuote = '"' + adUserInformation.userId + '"';

    var sqlGetUser = 'SELECT id, creation_time::CHAR(19) as creation_time, display_name, description, home_lat, home_lon, home_zoom, image_file_name, consider_pd, changesets_count, traces_count FROM users WHERE id < 0 AND (description = \'{{userId}}\' OR description = \'{{userIdQuote}}\')';
    var getNewId = 'SELECT CASE WHEN min(id) < 0 THEN min(id) - 1 ELSE -1 END AS id FROM users';
    var getTokens = 'SELECT request_token, request_token_secret, access_token, access_token_secret, user_id FROM sessions WHERE request_token = \'{{oauth_token}}\'';

    database({
      params: adUserInformation
    }).query([getNewId, getTokens, sqlGetUser], 'user', function(e, r) {

      var dbUserInfo = r.data.user[2] ? r.data.user[2] : {};
      var tokens = {
        requestToken: r.data.user[1] ? r.data.user[1].request_token : null,
        requestTokenSecret: r.data.user[1] ? r.data.user[1].request_token_secret : null,
        oauthAccessToken: r.data.user[1] && r.data.user[1].access_token ? r.data.user[1].access_token : tools.uid(40),
        oauthAccessTokenSecret: r.data.user[1] && r.data.user[1].access_token_secret ? r.data.user[1].access_token_secret : tools.uid(40)
      };


      var userInformation = {
        'id': dbUserInfo.id || (r.data.user[0] ? r.data.user[0].id : null), // Query Database for next available id
        'account_created': dbUserInfo.creation_time || (new Date()).toISOString(), //Query Database for either when they were enter to our DB or now
        'display_name': adUserInformation.name,
        'description': adUserInformation.userId,
        'home': {
          'lat': dbUserInfo.home_lat || '38.893889',
          'lon': dbUserInfo.home_lon || '-77.0425',
          'zoom': dbUserInfo.home_zoom || '3'
        },
        'img': {
          'href': dbUserInfo.image_file_name || 'http://www.nps.gov/npmap/tools/assets/img/places-icon.png'
        },
        'contributor-terms': {
          'pd': dbUserInfo.consider_pd || 't'
        },
        'changesets': {
          'count': 0
        },
        'traces': {
          'count': 0
        }
      };
      tools.addUser(tokens, callback)(null, userInformation);
    });
  },
  accessToken: function(authHeader, callback) {
    var auths = tools.splitAuthHeader(authHeader);
    var getTokens = 'SELECT request_token, request_token_secret, access_token, access_token_secret, user_id FROM sessions WHERE request_token = \'{{oauth_token}}\'';
    var tokens = {
      requestToken: auths.oauth_token
    };


    database({
      params: auths
    }).query(getTokens, 'session', function(e, r) {
      if (r.data.session[0]) {
        tokens.requestTokenSecret = r.data.session[0].request_token_secret;
        tokens.oauthAccessToken = r.data.session[0].access_token;
        tokens.oauthAccessTokenSecret = r.data.session[0].access_token_secret;
      }
      tools.getUserInfo(tokens.requestToken, tokens.requestTokenSecret, tokens.oauthAccessToken, tokens.oauthAccessTokenSecret, function(error, username, userId) {
        callback(error, tokens.oauthAccessToken, tokens.oauthAccessTokenSecret, username, userId);
      });
    });
  },
  authorize: function(req, res) {
    //var returnUrl = 'http://10.147.150.14:8000/oauth/verify_active_directory' + encodeURIComponent(req._parsedUrl.search);
    var returnUrl = 'http://insidemaps.nps.gov/dist_dev/land.html' + encodeURIComponent(req._parsedUrl.search);
    res.redirect('https://insidemaps.nps.gov/account/logon/?ReturnUrl=' + returnUrl);
  },
  requestToken: function(callback) {
    tools.addRequestToken(tools.uid(40), tools.uid(40), function(a, b, c) {
      callback(a, b, c);
    });
  }
};
