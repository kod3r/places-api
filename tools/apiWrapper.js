var xmlJs = require('../../xmljs_translator'),
config = require('../config'),
errorList = require('./errorList');

var getParams = function(req) {
  // Deal with any params after a question mark
  var newParamsRaw = req._parsedUrl.query ? req._parsedUrl.query.split('&') : [];
  var newParams = {};
  newParamsRaw.map(function(params) {
    var param = params.split(/=(.*)/, 2);
    if (param.length === 2) {
      newParams[param[0].toLowerCase()] = param[1];
    }
  });
  return newParams;
};

var modifiedResults = function(req, res) {

  var buildResponse = function(result) {
    // Converts the JSON response to pretty print, jsonp, or XML
    var indent = getParams(req).pretty ? 2 : null,
    response = {};

    if (req.params && req.params.format === 'json' || req.params.format === 'jsonp') {
      // Pretty Print JSON
      response.result = JSON.stringify(result,null,indent);
      response.contentType = 'application/json';

      // Check for jsonp
      if (getParams(req).callback) {
        response.contentType = 'application/javascript';
        response.result = [getParams(req).callback, '(', result, ');'].join('');
      }
    } else {
      // OSM XML
      response.contentType = 'application/xml';
      response.result = xmlJs.xmlify(result, {'prettyPrint': indent});
    }

    return response;
  };

  return {
    send: function(inData) {
      // Send is used to report data back to the browser
      var result, response;

      // All OSM data is wrapped in an OSM tag
      // http://wiki.openstreetmap.org/wiki/API_v0.6#XML_Format
      result = {
        'osm': JSON.parse(JSON.stringify(config.appInfo))
      };

      // Replace the 'name' field with 'generator'
      result.osm.generator = result.osm.name;
      delete result.osm.name;

      // Add the data to the wrapper
      for (var key in inData) {
        if (inData.hasOwnProperty(key)) {
          result.osm[key] = inData[key];
        }
      }

      response = buildResponse(result);
      res.set('Content-Type', response.contentType);
      res.send(response.result);
    },
    status: function(statusCode, description, details) {
      // Status is used for error reporting
      var result, response;

      // Build a description of the error
      result = {
        'error' : {
          'message': errorList[statusCode],
          'status': statusCode,
          'details': details
        },
        parameters: getParams(req)
      };

      // Ignore the status code if the 'suppress_response_codes' tag is set
      if (getParams(req).suppress_status_codes) {
        statusCode = 200;
      }

      response = buildResponse(result);
      res.set('Content-Type', response.contentType);
      res.status(statusCode).send(response.result);
    }
  };
};


var addMethod = function(method, path, callback, app) {

  //Extends the API calls to allow for more modification

  // Add the version number to the path
  var newPath = ['/', config.appInfo.version, '/', path, '.:format?'].join('');
  console.log('addMethod', newPath);

  //create the get request
  method = method.toLowerCase();
  app[method](newPath, function(req, res) {

    // Modify the req and the res to add extra features
    var newRes = {};
    newRes.send = modifiedResults(req, res).send;
    newRes.status = modifiedResults(req, res).status;

    // Callback the original request
    callback(req, newRes);
  });
};

exports = module.exports = function(app) {
  return {
    getParams: getParams,
    allow: function(method, path, callback) {addMethod(method, path, callback, app);}
  };
};

