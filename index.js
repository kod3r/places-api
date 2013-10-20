var express = require('express'),
app = express(),
poiApp = require('./tools/apiWrapper')(app),
api06 = require('./apis/0.6'),
allowXSS = require('./tools/allowXSS');
exports.routes = function() {

  // From http://wiki.openstreetmap.org/wiki/API_v0.6#General_information

  //TODO: REQUIRE OAUTH http://wiki.openstreetmap.org/wiki/OAuth

  // Allow external webpages to read our JavaScript
  allowXSS(app);

  // API Calls
  api06.map(function(apiCall) {
    poiApp.allow(apiCall.method, apiCall.path, apiCall.process);
  });

  return app;
};
