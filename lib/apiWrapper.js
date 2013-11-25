var xmlJs = require('xmljs_translator'),
config = require('../config'),
errorList = require('./errorList'),
zlib = require('zlib'),
osmGeojson = require('osm-and-geojson'),
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
    //console.log(result);
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
      'html': function(){
        // Return an HTML document with the result (not implemented);
        var regex = new RegExp('/.+?/(.+?)\\..*');
        var options = {};
        options.title = req.url.replace(regex, function(a, $1){return $1;});
        response.render = 'map'; //options.title;
        options.geojsonLink = '..' + req.url.replace('.html', '.geojson');
        options.geojson = wrapResponse(result, params);
        options.geojson = JSON.stringify(osmGeojson.osm2geojson(xmlJs.xmlify(options.geojson)));

        if (JSON.stringify(req.query).length > 2) {options.subtitle = JSON.stringify(req.query,null,2);}
        response.renderOptions = options;

        return response;
      },
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
      },
      'geojson': function() {
        result = wrapResponse(result, params);
        result = osmGeojson.osm2geojson(xmlJs.xmlify(result, {'prettyPrint': indent}));
        response.contentType = 'application/json';
        response.result = JSON.stringify(result,null,indent);

        // Check for jsonp
        if (req.query.callback) {
          response.contentType = 'application/javascript';
          response.result = [req.query.callback, '(', JSON.stringify(result,null,indent), ');'].join('');
        }

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
      if (response && response.render) {
        res.render(response.render, response.renderOptions);
      } else {
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

var newResult = function(auth, callback) {
  return function(req, res, next) {
    var newRes = {};
    newRes.send = modifiedResults(req, res, next).send;
    newRes.status = modifiedResults(req, res, next).status;
    //console.log('url', req.url);
    //console.log('params', req.params);
    //console.log('headers', req.headers);

    var unauthorized = function () {
      res.statusCode = 401;
      res.setHeader('WWW-Authenticate', 'Basic realm="Authorization Required"');
      res.end('Unauthorized');
    };

    if (auth) {
      // Deal with basic auth
      if (auth.basic && req.headers.authorization && req.headers.authorization.indexOf(' ') > 0 && req.headers.authorization.split(' ')[0] === 'Basic') {
        // We have a basic oauth to verify
        auth.basic(req, newRes, unauthorized, callback);
      } else if (auth.oauth && req.headers.authorization && req.headers.authorization.indexOf(' ') > 0 && req.headers.authorization.split(' ')[0] === 'OAuth') {
        // We have oauth to verify
        auth.oauth(req, newRes, callback);
      } else {
        // This requires authorization, and the user didn't submit any
        unauthorized();
      }
    }
    else {
      callback(req, newRes);
    }
  };
};

var addMethod = function(method, path, version, app, auth, callback) {

  //Extends the API calls to allow for more modification
  // Add the version number to the path
  version = version ? '/' + version : '';
  var newPath = [version, '/', path, '.:format?'].join('');

  // Modify the req and the res to add extra features
  //create the get request
  method = method.toLowerCase();
  app[method](newPath, newResult(auth, callback));
  console.log('addMethod', newPath, auth);

};
exports = module.exports = function(app) {
  return {
    allow: function(method, path, version, auth, callback) {addMethod(method, path, version, app, auth, callback);}
  };
};
