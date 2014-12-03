var oauthorize = require('oauthorize'),
  utils = require('utils'),
  extras = {
    server: oauthorize.createServer()
  };
module.exports = {
  accessToken: function(authHeader, callback) {
    //callback(error, accessToken, accessTokenSecret, username, userId);
  },
  authorize: function(req, res) {
    //res.something;
  },
  requestToken: function(callback) {
    //passport.authenticate('consumer', { session: false }),
    extras.server.requestToken(function(client, callbackURL, done) {
      var token = utils.uid(8),
        secret = utils.uid(32);
      callback(null, token, secret);
      return done(null, token, secret);
    });
  }
};
