/* jshint camelcase: false */
var extras = require('./tools');
module.exports = function(req, callback) {
  var auths = extras.splitAuthHeader(req.headers.authorization);
  extras.getAccessSecret(auths.oauth_token, function(tokens) {
    if (tokens) {
      extras.getUserInfo(tokens.request_token, tokens.request_token_secret, auths.oauth_token, tokens.access_token_secret, function(e, username, userId) {
        // Verify the signature
        var origSig = auths.oauth_signature,
          requestedUrl = req.protocol + '://' + req.get('Host') + req.originalUrl,
          compareSig = extras.osmOauth._getSignature(req.method, requestedUrl, extras.verification.baseString(auths), tokens.access_token_secret),
          josmCompareSig = extras.josmOauth._getSignature(req.method, requestedUrl, extras.verification.baseString(auths), tokens.access_token_secret);
        if (encodeURIComponent(compareSig) === origSig || encodeURIComponent(josmCompareSig) === origSig) {
          callback({
            'valid': !e,
            'userId': userId,
            'username': username
          });
        } else {
          callback({
            'valid': false
          });
        }
      });
    } else {
      callback({
        'valid': false
      });
    }
  });
};
