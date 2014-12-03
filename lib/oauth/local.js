var server = require('oauthorize').createServer(),
console.log('1');
module.exports = {
  accessToken: function(authHeader, callback) {
    //callback(error, accessToken, accessTokenSecret, username, userId);
  },
  authorize: function(req, res) {
    //res.something;
  },
  requestToken: function(callback) {
    //passport.authenticate('consumer', { session: false }),
    server.requestToken(function(client, callbackURL, done) {
      var token = uid(8),
        secret = uid(32);
      callback(null, token, secret);
      return done(null, token, secret);
    });
  }
};
