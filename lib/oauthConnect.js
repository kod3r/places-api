var oauthFunctions = require('./oauthFunctions');

//TODO: REMOVE THESE SOON
var config = require('../config');
var xmlJs = require('xmljs_translator');


exports = module.exports = [{
  'name': 'Request Token',
  'description': 'Gets a request token from the OAuth provider and passes that information back to the calling code.',
  'method': 'POST',
  'path': '/request_token',
  'process': function (req, res) {
    oauthFunctions.osmOauth.getOAuthRequestToken(function(error, token, tokenSecret) {
      if (error) {
        res.status(error.statusCode || 500);
        res.send(error);
      } else {
        oauthFunctions.keys[token] = {
          'oauth_token_secret': tokenSecret
        };
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
    var authName = {'token': 'oauth_token', 'key': 'oauth_token_secret'},
    auths = oauthFunctions.splitAuthHeader(req.headers.authorization);
    console.log(auths);
    oauthFunctions.osmOauth.getOAuthAccessToken(auths[authName.token],oauthFunctions.keys[auths[authName.token]][authName.key], function (error, oauthAccessToken, oauthAccessTokenSecret) {
      if (error) {
        res.status(error.statusCode || 500);
        res.send(error);
      } else {
        // Maybe we can get the user name?
        // TODO: Clean this up, and move the get user details to the oauthFunctions file
        oauthFunctions.osmOauth.get(
          'http://' + config.oauth.server + '/api/0.6/user/details',
          oauthAccessToken,
          oauthAccessTokenSecret,
          function (e, data){
            var jsonData = xmlJs.jsonify(data);
            oauthFunctions.keys[auths[authName.token]].userName = jsonData.osm.user.display_name;
            oauthFunctions.keys[auths[authName.token]].id = jsonData.osm.user.id;
            oauthFunctions.keys[auths[authName.token]].userXml = data;
            res.send([
              'oauth_token=', oauthAccessToken,
              '&oauth_token_secret=', oauthAccessTokenSecret,
              '&username=', oauthFunctions.keys[auths[authName.token]].userName,
              '&userId=', oauthFunctions.keys[auths[authName.token]].id
            ].join(''));
          });
      }
    });
  }
}];
