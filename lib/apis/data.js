/* jshint camelcase: false */

var config = require('../../config'),
  queries = require('./sql/dataSql'),
  database = require('../database')('pgs'),
  apiFunctions = require('./apiFunctions'),
  tileMath = require('../tileMath');

// These are all the calls we need to handle
exports = module.exports = [{
  'name': 'GET points',
  'description': 'Queries the map.',
  'format': 'url',
  'method': 'GET',
  'path': 'points',
  'auth': apiFunctions.auth,
  'process': function(req, res) {
  
    if (req.query.bbox) {
      req.params.minLon = req.query.bbox.split(',')[0]; //'-75.5419922';
      req.params.minLat = req.query.bbox.split(',')[1]; //'39.7832127';
      req.params.maxLon = req.query.bbox.split(',')[2]; //'-75.5364990';
      req.params.maxLat = req.query.bbox.split(',')[3]; //'39.7874339';
    }
    if (req.query.types) {
      req.params.typeArray = req.query.types.split(',');
    }
  
    res.send({
      'api': config.capabilities
    });
  }
}];
