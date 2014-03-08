var express = require('express'),
  app = express(),
  config = require('./config');
app.use(express.bodyParser());
var poiApp = require('./lib/apiWrapper')(app),
  apiXapi = require('./lib/apis/xapi'),
  oauth = require('./lib/oauth/paths'),
  allowXSS = require('./lib/allowXSS');
exports.routes = function() {

  // From http://wiki.openstreetmap.org/wiki/API_v0.6#General_information

  // Allow external webpages to read our JavaScript
  allowXSS(app);

  // API Calls
  apiXapi.map(function(apiCall) {
    poiApp.allow(apiCall.method, apiCall.path, '0.6', apiCall.auth, apiCall.process);
  });

  // Overall capabilities
  poiApp.allow('GET', 'capabilities', null, null, function(req, res) {
    res.send({
      'api': config.capabilities
    });
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
