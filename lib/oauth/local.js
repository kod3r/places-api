/* jshint camelcase: false */

var tools = require('./tools');
module.exports = {
  addUser: function(userInformation, callback) {
    console.log(userInformation);
    callback(null, userInformation);
  },
  accessToken: function(authHeader, callback) {
    var auths = tools.splitAuthHeader(authHeader);
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
  authorize: function(req, res) {
    //var returnUrl = 'http://10.147.150.14:8000/oauth/verify_active_directory' + encodeURIComponent(req._parsedUrl.search);
    var returnUrl = 'http://insidemaps.nps.gov/dist_dev/land.html' + encodeURIComponent(req._parsedUrl.search);
    res.redirect('https://insidemaps.nps.gov/account/logon/?ReturnUrl=' + returnUrl);
  },
  requestToken: function(callback) {
    tools.addRequestToken(tools.uid(40), tools.uid(40), function(a, b, c) {
      console.log('a', a, 'b', b, 'c', c);
      callback(a, b, c);
    });
  }
};
