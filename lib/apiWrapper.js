var xmlJs = require('xmljs_translator'),
config = require('../config'),
errorList = require('./errorList'),
zlib = require('zlib'),
modifiedResults = function(req, res) {

  var wrapResponse = function(inData, params) {
    var result = {}, key, type;

    type = params && params.wrapType ? params.wrapType : 'osm';
    // All OSM data is wrapped in an OSM or DIFFRESULT tag
    // http://wiki.openstreetmap.org/wiki/API_v0.6#XML_Format
    result[type] = JSON.parse(JSON.stringify(config.appInfo));

    // Replace the 'name' field with 'generator'
    result[type].generator = result[type].name;
    delete result[type].name;

    // Add the data to the wrapper
    for (key in inData) {
      if (inData.hasOwnProperty(key)) {
        result[type][key] = inData[key];
      }
    }

    return result;
  },
  buildResponse = function(result, format, params) {
    // Converts the JSON response to pretty print, jsonp, or XML
    var indent = req.query.pretty ? 2 : null,
    response = {},
    validFormat = false,
    formatResponse = {
      'json': function() {
        // Pretty Print JSON
        response = {};
        result = wrapResponse(result, params);
        response.result = JSON.stringify(result,null,indent);
        response.contentType = 'application/json';

        // Check for jsonp
        if (req.query.callback) {
          response.contentType = 'application/javascript';
          response.result = [req.query.callback, '(', JSON.stringify(result,null,indent), ');'].join('');
        }

        return response;
      },
      /*'html': function(){
      // Return an HTML document with the result (not implemented);
      response.contentType = 'text/html';
      response.result = '<HTML><BODY>Html return type not yet implemented</BODY></HTML>';
      return response;
      },*/
      'txt': function() {
        // Return just the values, no padding around it
        response.contentType = 'text/html';
        if (typeof(result) === 'object') {
          response.result = JSON.stringify(result, null, 2);
        } else {
          response.result = result.toString();
        }
        return response;
      },
      'xml': function() {
        // OSM XML
        result = wrapResponse(result, params);
        response.contentType = 'application/xml';
        response.result = xmlJs.xmlify(result, {'prettyPrint': indent});
        return response;
      }
    };

    if (req.params) {
      // Allow for a default format to be set, then try xml if nothing is specified
      format = req.params.format ? req.params.format : format;
      if (format === 'jsonp') {format = 'json';}
    }
    for (var formatName in formatResponse) {
      if (formatName === format) {
        validFormat = true;
      }
    }
    if (!validFormat) {format = 'xml';}

    return formatResponse[format]();
  };

  return {
    send: function(inData, format, params) {
      // Send is used to report data back to the browser
      var response, buf;

      response = buildResponse(inData, format, params);
      res.set('Content-Type', response.contentType);

      // If the request headers accept gzip, return it in gzip
      if (req.headers['accept-encoding'] && req.headers['accept-encoding'].split(',').indexOf('gzip') >= 0) {
        res.set('Content-Encoding', 'gzip');
        buf = new Buffer(response.result, 'utf-8');
        zlib.gzip(buf, function (err, result) {
          res.end(result);
        });
      } else {
        res.send(response.result);
      }
    },
    status: function(error, format, params) {
      // TODO: Should errors be reported in HTML?
      // Status is used for error reporting
      var result, response;

      // Allow for reporting or poorly reported errors
      error = error || {};
      error.statusCode = error.statusCode || 500;
      error.details = error.details || 'No details provided';
      error.description = error.description || 'No description provided';

      // Build a description of the error
      result = {
        'error' : {
          'message': errorList[error.statusCode],
          'status': error.statusCode,
          'description': error.description,
          'details': error.details,
        },
        parameters: req.query,
        body: req.body,
        query: error.query
      };

      // Ignore the status code if the 'suppress_response_codes' tag is set
      var suppressStatusCodes = 'suppress_status_codes'; // Hack to keep JSHint from bugging me about camel case
      if (req.query[suppressStatusCodes]) {
        error.statusCode = 200;
      }

      response = buildResponse(result, format, params);
      res.set('Content-Type', response.contentType);
      res.status(error.statusCode).send(response.result);
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

