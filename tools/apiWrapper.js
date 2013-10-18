var osmXml = require('./osmXml'),
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
  return {
    send: function(inData) {
      var contentType,
      indent = getParams(req).pretty ? 2 : null;

      // All OSM data is wrapped in an OSM tag
      // http://wiki.openstreetmap.org/wiki/API_v0.6#XML_Format
      var result = {
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

      if (req.params && req.params.format === 'json' || req.params.format === 'jsonp') {
        // Pretty Print JSON
        result = JSON.stringify(result,null,indent);
        contentType = 'application/json';

        // Check for jsonp
        if (getParams(req).callback) {
          contentType = 'application/javascript';
          result = [getParams(req).callback, '(', result, ');'].join('');
        }
      } else {
        // OSM XML
        contentType = 'application/xml';
        result = osmXml.convert(result, {'prettyPrint': indent});
      }

      res.set('Content-Type', contentType);
      res.send(result);
    },
    status: function(statusCode, description) {
      var returnLines = [],
      contentType = 'text/html';

      // Create a description page (this will need to be updated to use our normal template)
      if (errorList[statusCode]) {
        returnLines.push('<h1>' + statusCode + ': ' + errorList[statusCode] + '</h1>');
      } else {
        returnLines.push('<h1> Error: ' + statusCode + '</h1>');
      }
      if (description) {
        returnLines.push('<hr><h4><span style=\'color:dd0000;\'>Description:</span>' + description + '</h4>');
      }
      res.set('Content-Type', contentType);
      res.status(statusCode).send(returnLines.join(''));
    }
  };
};


var addMethod = function(method, path, callback, app) {

  //Extends the API calls to allow for more modification

  // Add the version number to the path
  var newPath = ['/', config.appInfo.version, '/', path, '.:format?'].join('');
  console.log(newPath);

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

