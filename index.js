var express = require('express'),
apiWrapper = require('./tools/apiWrapper'),
osmApi = require('./tools/osmApi'),
allowXSS = require('./tools/allowXSS'),
app = express(),
poiApp = apiWrapper(app);
exports.routes = function() {

  // From http://wiki.openstreetmap.org/wiki/API_v0.6#General_information

  //TODO: REQUIRE OAUTH http://wiki.openstreetmap.org/wiki/OAuth

  // Allow external webpages to read our JavaScript
  allowXSS(app);

  // API Calls
  osmApi.apiCalls.map(function(apiCall) {
    poiApp.allow(apiCall.method, apiCall.path, apiCall.process);
  });

  return app;
};
