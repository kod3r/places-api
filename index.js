var express = require('express'),
  config = require('./config'),
  apiXapi = require('./lib/apis/xapi'),
  oauth = require('./lib/oauth/paths'),
  allowXSS = require('./lib/allowXSS'),
  bodyParser = require('body-parser');
// Set the environment variables

exports.routesNew = function() {
  var app = express.Router();
  app.get('/t', function(req, res) {
    console.log('%s %s %s', req.method, req.url, req.path);
    res.send('hi');
  });
  return app;
};

exports.routes = function() {

  var app = express.Router();
  var poiApp = require('./lib/apiWrapper')(app);
  // app.use(bodyParser.json);
  // app.use(bodyParser.urlencoded({
  //   extended: false
  // }));


  // From http://wiki.openstreetmap.org/wiki/API_v0.6#General_information

  // Allow external webpages to read our JavaScript
  // allowXSS(app);

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
  var app = express.Router();
  app.use(bodyParser.json);
  app.use(bodyParser.urlencoded({
    extended: false
  }));

  // Return the oauth calls
  oauth.map(function(oauthCall) {
    app[(oauthCall.method).toLowerCase()](oauthCall.path, oauthCall.process);
  });

  return app;
};
