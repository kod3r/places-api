var express = require('express'),
  bodyParser = require('body-parser'),
  allowXSS = require('./src/allowXSS');

var errorWrapper = function(errorFunction) {
  return function(err, req, res, next) {
    console.log('ERROR', err);
    errorFunction(err, req, res, next);
  };
};

module.exports = function(config) {

  config = config || require('./config');
  var apiData = require('./src/apis/data')(config),
    apiXapi = require('./src/apis/xapi')(config),
    oauth = require('./src/oauth/paths')(config);

  return {
    'routes': function() {
      var router = express.Router(),
        placesApp = require('./src/apiWrapper')(router, config);
      // From http://wiki.openstreetmap.org/wiki/API_v0.6#General_information
      // Allow external webpages to read our JavaScript
      allowXSS(router);

      // API Calls
      apiXapi.map(function(apiCall) {
        placesApp.allow(apiCall.method, apiCall.path, '0.6', apiCall.format, apiCall.auth, apiCall.process);
      });

      // Data Calls
      apiData.map(function(apiCall) {
        placesApp.allow(apiCall.method, apiCall.path, 'data', apiCall.format, apiCall.auth, apiCall.process);
      });

      // Overall capabilities
      placesApp.allow('GET', 'capabilities', null, null, null, function(req, res) {
        res.send({
          'api': config.capabilities
        });
      });

      router.use(errorWrapper(placesApp.onError));
      return router;
    },
    'oauth': function() {
      var router = express.Router();

      // Return the oauth calls
      oauth.map(function(oauthCall) {
        router[(oauthCall.method).toLowerCase()](oauthCall.path, bodyParser.json(), oauthCall.process);
      });

      router.use(errorWrapper(function(err, res){
        res.set('Content-Type', 'text/html');
        res.status(500).send(JSON.stringify(err, null, 2));
      }));

      return router;
    }
  };
};
