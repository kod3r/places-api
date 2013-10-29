var xmlJs = require('../../xmljs_translator'),
config = require('../config'),
errorList = require('./errorList'),
zlib = require('zlib');

var modifiedResults = function(req, res) {

  var buildResponse = function(result) {
    // Converts the JSON response to pretty print, jsonp, or XML
    var indent = req.query.pretty ? 2 : null,
    response = {};

    if (req.params && req.params.format === 'json' || req.params.format === 'jsonp') {
      // Pretty Print JSON
      response.result = JSON.stringify(result,null,indent);
      response.contentType = 'application/json';

      // Check for jsonp
      if (req.query.callback) {
        response.contentType = 'application/javascript';
        response.result = [req.query.callback, '(', result, ');'].join('');
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
      var result, response, buf;

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

      // If the request headers accept gzip, return it in gzip
      if (req.headers['accept-encoding'].split(',').indexOf('gzip') >= 0) {
        res.set('Content-Encoding', 'gzip');
        buf = new Buffer(response.result, 'utf-8');
        zlib.gzip(buf, function (err, result) {
          res.end(result);
        });
      } else {
        res.send(response.result);
      }
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
        parameters: req.query
      };

      // Ignore the status code if the 'suppress_response_codes' tag is set
      if (req.query.suppress_status_codes) {
        statusCode = 200;
      }

      response = buildResponse(result);
      res.set('Content-Type', response.contentType);
      res.status(statusCode).send(response.result);
    }
  };
};


var addMethod = function(method, path, version, app, callback) {

  //Extends the API calls to allow for more modification

  // Add the version number to the path
  version = version ? '/' + version : '';
  var newPath = [version, '/', path, '.:format?'].join('');
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
    allow: function(method, path, version, callback) {addMethod(method, path, version, app, callback);}
  };
};

