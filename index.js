var express = require('express'),
app = express(),
config = require('./config');
app.use(express.bodyParser());
var poiApp = require('./lib/apiWrapper')(app),
api06 = require('./lib/apis/0.6'),
oauth = require('./lib/oauthConnect'),
allowXSS = require('./lib/allowXSS');
exports.routes = function() {

  // From http://wiki.openstreetmap.org/wiki/API_v0.6#General_information

  //TODO: REQUIRE OAUTH http://wiki.openstreetmap.org/wiki/OAuth

  // Allow external webpages to read our JavaScript
  allowXSS(app);

  // API Calls
  api06.map(function(apiCall) {
    poiApp.allow(apiCall.method, apiCall.path, '0.6', apiCall.process);
  });

  // Overall capabilities
  poiApp.allow('GET', 'capabilities', null, function(req, res) {
    res.send({'api':config.capabilities});
  });

  return app;
};

exports.oauth = function() {

  // Return the oauth calls
  oauth.map(function(oauthCall) {
    app[(oauthCall.method).toLowerCase()](oauthCall.path, oauthCall.process);
  });

  return app;
};
