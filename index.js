var express = require('express'),
app = express(),
config = require('./config'),
poiApp = require('./lib/apiWrapper')(app),
api06 = require('./lib/apis/0.6'),
oauth = require('oauth'),
allowXSS = require('./lib/allowXSS');
app.use(express.bodyParser());
exports.routes = function() {

  // From http://wiki.openstreetmap.org/wiki/API_v0.6#General_information

  //TODO: REQUIRE OAUTH http://wiki.openstreetmap.org/wiki/OAuth

  // Allow external webpages to read our JavaScript
  allowXSS(app);

  // API Calls
  api06.map(function(apiCall) {
    poiApp.allow(apiCall.method, apiCall.path, '0.6', apiCall.process);
  });

  // Overall capabilities (this is sort of duplicated?
  poiApp.allow('GET', 'capabilities', null, function(req, res) {
    res.send({'api':config.capabilities});
  });

  return app;
};

exports.oauth = function() {

  var osmOauth = new oauth.OAuth(
    'http://api06.dev.openstreetmap.org/oauth/request_token',
    'http://api06.dev.openstreetmap.org/oauth/access_token',
    'g3cmPe2OSqxkDmSIi8tOZjG4s1DYQtgtyYOOq1yx',
    'VaqYSfpCGFOletdeDaPanfrpbrZbQh38ytBLo3mX',
    '1.0',
    null,
    'HMAC-SHA1'
  );

  app.post('/request_token', function (req, res) {
    osmOauth.getOAuthRequestToken(function(error, token, tokenSecret) {
      if (error) {
        res.status(500);
        res.send(error);
      } else {
        res.send(['oauth_token=', token, '&oauth_token_secret=', tokenSecret].join(''));
      }
    });
  });
  app.get('/authorize', function (req, res) {
    console.log(req.originalUrl);
    res.redirect('http://api06.dev.openstreetmap.org' + req.originalUrl);
  });
  app.post('/access_token', function (req, res) {
    // oauth_token=1XvzPQtT8BXKQwg4D6THs4T1Lf8ALstPTMmmGb9N&oauth_token_secret=7lZ7MFVh4mDbXj60uWqiaXI0faMilibfCKdpNeVQ
    // res.send(JSON.stringify(req.query, null, 2));

    // must find a better way to do this
    var auths = req.headers.authorization.split(' ');
    var authObj = {};
    for (var auth in auths) {
      if (auths[auth].indexOf('=') >= 0) {
        authObj[auths[auth].split('=')[0]] = auths[auth].split('=')[1].replace(/\"/g, '').replace(/,/g, '');
      }
    }


    osmOauth.getOAuthAccessToken(auths['oauth_token'],auths['oauth_consumer_key'], function (error, oauthAccessToken, oauthAccessTokenSecret) {
      if (error) {
        res.status(500);
        console.log(authObj);
        res.send(error);
      } else {
        res.send(['oauth_token=', oauthAccessToken, '&oauth_token_secret=', oauthAccessTokenSecret].join(''));
      }
    });
  });


  return app;
};
