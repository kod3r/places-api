var config = require('../config'),
xmlJs = require('xmljs_translator'),
OAuthStrategy = require('passport-oauth').OAuthStrategy,
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
},
keys = {};
