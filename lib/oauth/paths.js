var oauthFunctions = require('./oauthFunctions');

exports = module.exports = [{
  'name': 'Request Token',
  'description': 'Gets a request token from the OAuth provider and passes that information back to the calling code.',
  'method': 'POST',
  'path': '/request_token',
  'process': function(req, res) {
    oauthFunctions.requestToken(function(error, token, tokenSecret) {
      if (error) {
        res.status(error.statusCode || 500);
        res.send(error);
      } else {
        res.send(['oauth_token=', token, '&oauth_token_secret=', tokenSecret].join(''));
      }
    });
  }
}, {
  'name': 'Authorize',
  'description': 'Forwards user to the OAuth provider site for login and token exchange',
  'method': 'GET',
  'path': '/authorize',
  'process': function(req, res) {
    oauthFunctions.authorize(req, res);
  }
}, {
  'name': 'Access Token',
  'description': 'Requests the oauth_token and oauth_token_secret from the OAuth provider',
  'method': 'POST',
  'path': '/access_token',
  'process': function(req, res) {
    oauthFunctions.accessToken(req.headers.authorization, function(error, oauthAccessToken, oauthAccessTokenSecret, username, userId) {
      if (error) {
        res.status(error.statusCode || 500);
        res.send(error);
      } else {
        res.send([
          'oauth_token=', oauthAccessToken,
          '&oauth_token_secret=', oauthAccessTokenSecret,
          '&username=', username,
          '&userId=', userId
        ].join(''));
      }
    });
  }
}];
