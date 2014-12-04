/* jshint camelcase: false */

var config = require('../../config'),
  tools = require('./tools');

module.exports = {
  accessToken: function(auth, callback) {
    var auths = tools.splitAuthHeader(auth);
    tools.getTokenSecret(auths.oauth_token, function(tokenSecret) {
      tools.osmOauth.getOAuthAccessToken(auths.oauth_token, tokenSecret, function(error, oauthAccessToken, oauthAccessTokenSecret) {
        if (error) {
          callback(error);
        } else {
          // Get the user info
          tools.getUserInfo(auths.oauth_token, tokenSecret, oauthAccessToken, oauthAccessTokenSecret, function(e, username, userId) {
            callback(error, oauthAccessToken, oauthAccessTokenSecret, username, userId);
          });
        }
      });
    });
  },
  requestToken: function(callback) {
    tools.osmOauth.getOAuthRequestToken(function(error, token, tokenSecret) {
      tools.addRequestToken(token, tokenSecret, function() {
        callback(error, token, tokenSecret);
      });
    });
  },
  authorize: function(req, res) {
    res.redirect('http://' + config.oauth.server + req.originalUrl);
  }
};
