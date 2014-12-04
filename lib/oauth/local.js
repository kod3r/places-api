/* jshint camelcase: false */

var tools = require('./tools');
module.exports = {
  accessToken: function(authHeader, callback) {
    console.log('1', authHeader);
    var auths = tools.splitAuthHeader(authHeader);
    console.log('2', auths);
    tools.getTokenSecret(auths.oauth_token, function(tokenSecret) {
      console.log('3', tokenSecret);
      tools.osmOauth.getOAuthAccessToken(auths.oauth_token, tokenSecret, function(error, oauthAccessToken, oauthAccessTokenSecret) {
        console.log('4', error, oauthAccessToken, oauthAccessTokenSecret);
        if (error) {
          console.log('5', error);
          callback(error);
        } else {
          // Get the user info
          console.log('6');
          tools.getUserInfo(auths.oauth_token, tokenSecret, oauthAccessToken, oauthAccessTokenSecret, function(e, username, userId) {
            console.log('7', e, username, userId);
            callback(error, oauthAccessToken, oauthAccessTokenSecret, username, userId);
          });
        }
      });
    });
  },
  authorize: function(req, res) {
    res.render('login');
  },
  requestToken: function(callback) {
    tools.addRequestToken(tools.uid(40), tools.uid(40), function(a, b, c) {
      console.log('a', a, 'b', b, 'c', c);
      callback(a, b, c);
    });
  }
};
