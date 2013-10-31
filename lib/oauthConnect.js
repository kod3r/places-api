var config = require('../config'),
oauth = require('oauth'),
osmOauth = new oauth.OAuth(
  'http://' + config.oauth.server + '/oauth/request_token',
  'http://' + config.oauth.server + '/oauth/access_token',
  config.oauth.consumerKey,
  config.oauth.consumerSecret,
  '1.0',
  null,
  'HMAC-SHA1'
),
splitAuthHeader = function(authorization) {
  // must find a better way to do this
  var auths = authorization.split(' '),
  authObj = {}, authIndex;
  for (authIndex in auths) {
    if (auths[authIndex].indexOf('=') >= 0) {
      authObj[auths[authIndex].split('=')[0]] = auths[authIndex].split('=')[1].replace(/\"/g, '').replace(/,/g, '');
    }
  }
  return authObj;
};

exports = module.exports = [{
  'name': 'Request Token',
  'description': 'Gets a request token from the OAuth provider and passes that information back to the calling code.',
  'method': 'POST',
  'path': '/request_token',
  'process': function (req, res) {
    osmOauth.getOAuthRequestToken(function(error, token, tokenSecret) {
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
  'process': function (req, res) {
    res.redirect('http://api06.dev.openstreetmap.org' + req.originalUrl);
  }
}, {
  'name': 'Access Token',
  'description': 'Requests the oauth_token and oauth_token_secret from the OAuth provider',
  'method': 'POST',
  'path': '/access_token',
  'process': function (req, res) {
    // oauth_token=1XvzPQtT8BXKQwg4D6THs4T1Lf8ALstPTMmmGb9N&oauth_token_secret=7lZ7MFVh4mDbXj60uWqiaXI0faMilibfCKdpNeVQ
    // res.send(JSON.stringify(req.query, null, 2));
    //
    //
    var authName = {'token': 'oauth_token', 'key': 'request_token_secret'},
    auths = splitAuthHeader(req.headers.authorization);
    console.log(auths);
    osmOauth.getOAuthAccessToken(auths[authName.token],auths[authName.key], function (error, oauthAccessToken, oauthAccessTokenSecret) {
      if (error) {
        res.status(error.statusCode || 500);
        res.send(error);
      } else {
        res.send(['oauth_token=', oauthAccessToken, '&oauth_token_secret=', oauthAccessTokenSecret].join(''));
      }
    });
  }
}];
