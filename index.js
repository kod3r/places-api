var express = require('express'),
  config = require('./config'),
  apiXapi = require('./lib/apis/xapi'),
  oauth = require('./lib/oauth/paths'),
  allowXSS = require('./lib/allowXSS'),
  bodyParser = require('body-parser');
// Set the environment variables
//
exports.routes = function() {
  var router = express.Router();
  // parse application/x-www-form-urlencoded
  router.use(bodyParser.urlencoded({
    extended: false
  }));
  //
  // // parse application/json
  router.use(bodyParser.json());

  var poiApp = require('./lib/apiWrapper')(router);

  // From http://wiki.openstreetmap.org/wiki/API_v0.6#General_information

  // Allow external webpages to read our JavaScript
  allowXSS(router);

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

  return router;
};

exports.oauth = function() {
  var router = express.Router();

  // Return the oauth calls
  oauth.map(function(oauthCall) {
    router[(oauthCall.method).toLowerCase()](oauthCall.path, oauthCall.process);
  });

  return router;
};
