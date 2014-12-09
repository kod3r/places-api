var express = require('express'),
  bodyParser = require('body-parser'),
  config = require('./config'),
  apiXapi = require('./lib/apis/xapi'),
  oauth = require('./lib/oauth/paths'),
  allowXSS = require('./lib/allowXSS');
// Set the environment variables
//
exports.routes = function() {
  var router = express.Router(),
    poiApp = require('./lib/apiWrapper')(router);
  // From http://wiki.openstreetmap.org/wiki/API_v0.6#General_information
  // Allow external webpages to read our JavaScript
  allowXSS(router);

  // API Calls
  apiXapi.map(function(apiCall) {
    poiApp.allow(apiCall.method, apiCall.path, '0.6', apiCall.format, apiCall.auth, apiCall.process);
  });

  // Overall capabilities
  poiApp.allow('GET', 'capabilities', null, null, null, function(req, res) {
    res.send({
      'api': config.capabilities
    });
  });

  return router;
};

exports.oauth = function() {
  var router = express.Router();

  // Return the oauth calls
  oauth.map(function(oauthCall) {
    router[(oauthCall.method).toLowerCase()](oauthCall.path, bodyParser.json(), oauthCall.process);
  });

  return router;
};
