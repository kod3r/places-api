/* jshint camelcase: false */

var apiFunctions = require('./apiFunctions'),
  database = require('../database')('pgs');
//config = require('../../config'),
//queries = require('./sql/dataSql'),

// These are all the calls we need to handle
exports = module.exports = [{
  'name': 'GET park',
  'description': 'Takes lat, lon, and a optional buffer and returns a park code or park codes.',
  'format': 'url',
  'method': 'GET',
  'path': 'park',
  'process': function(req, res) {
    // lat: latitude of a point in WGS84
    // lon: longitude of a point in WGS84

    var queryArray = [
      'SELECT',
      '  unit_code',
      'FROM',
      '  render_park_polys',
      'WHERE',
      '  ST_Within(ST_Transform(ST_SetSrid(ST_MakePoint(\'{{lon}}\',\'{{lat}}\'),4326),3857),poly_geom)',
      'ORDER BY',
      '  minzoompoly DESC',
      '  area DESC'
    ];

    //TODO: Convert query params into normal params

    var query = queryArray.join(' ');
    database(req, res).query(query, 'park', function(expressRes, dbResult) {
      if (dbResult && dbResult.data && dbResult.data.point && dbResult.data.point[0]) {
        // Remove the 'park' layer so the result is uniform with all the other results
        dbResult.data = apiFunctions.deleteEmptyTags(dbResult.data.park[0]);

        apiFunctions.respond(expressRes, dbResult);
      }
    });

  }
}, {
  'name': 'GET points',
  'description': 'Queries the map.',
  'format': 'url',
  'method': 'GET',
  'path': 'points',
  'process': function(req, res) {
    // https://github.com/nationalparkservice/places/issues/34

    //   bbox: (minLon, minLat, maxLon, maxLat)
    //   center (lon,lat)
    //   distance (in meters)
    //   case_sensitive: T/F (defaults to F)
    //   name: (comma separated list)
    //   name_like: (comma separated list of similar names)
    //   name_regex: (allows full control of the regular express to get names)
    //   type: (comma separated list)
    //   unit_code: (comma separated list)
    //
    //
    var queryArray = [
      'SELECT json_agg(to_json(pgs_current_nodes)) as node FROM',
      'pgs_current_nodes JOIN (',
      'SELECT DISTINCT nodes.id as node_id FROM',
      '( SELECT nodes.id, nodes.tags FROM nodes WHERE',
      'array_length(hstore_to_array(delete(tags, \'nps:places_uuid\')),1)/2 > 0 AND'
    ];


    // Convert the query items to parameters
    if (req.query.bbox) {
      req.params.minLon = parseFloat(req.query.bbox.split(',')[0], 10); //'-75.5419922';
      req.params.minLat = parseFloat(req.query.bbox.split(',')[1], 10); //'39.7832127';
      req.params.maxLon = parseFloat(req.query.bbox.split(',')[2], 10); //'-75.5364990';
      req.params.maxLat = parseFloat(req.query.bbox.split(',')[3], 10); //'39.7874339';
      queryArray.push('nodes.geom && ST_MakeEnvelope(\'{{minLon}}\',\'{{minLat}}\',\'{{maxLon}}\',\'{{maxLat}}\', 4326) AND');
    }

    if (req.query.center && req.query.center.split(',').length === 2 && req.query.distance) {
      req.params.distance = parseFloat(req.query.distance, 10);
      req.params.centerLon = parseFloat(req.query.center.split(',')[0], 10);
      req.params.centerLat = parseFloat(req.query.center.split(',')[1], 10);
      queryArray.push('nodes.geom && ST_Buffer(Geography(ST_MakePoint(\'{{centerLon}}\',\'{{centerLat}}\')), \'{{distance}}\') AND');
      queryArray.push('ST_DWithin (Geography(nodes.geom), Geography(ST_MakePoint(\'{{centerLon}}\',\'{{centerLat}}\')), \'{{distance}}\') AND');
    }

    queryArray.push('TRUE');
    queryArray.push(') nodes');
    if (req.query.type) {
      req.params.type = '^' + req.query.type.split(',').join('$|^') + '$';
      // queryArray.push('o2p_get_name(tags, \'N\', true) ~* \'{{type}}\' AND');
      queryArray.push('JOIN planet_osm_point ON nodes.id = planet_osm_point.osm_id AND planet_osm_point.fcat ~* \'{{type}}\'');
    }
    queryArray.push('WHERE');

    var comparison = req.query.case_sensitive && req.query.case_sensitive !== 'false' ? '~' : '~*';

    var nameQueries = [];
    if (req.query.name) {
      req.params.name = '^' + req.query.name.split(',').join('$|^') + '$';
      nameQueries.push('nodes.tags -> \'name\' ' + comparison + ' \'{{name}}\'');
    }

    if (req.query.name_like) {
      req.params.name_like = req.query.name_like.split(',').join('|');
      nameQueries.push('nodes.tags -> \'name\' ' + comparison + '  \'{{name_like}}\'');
    }

    if (req.query.name_regex) {
      req.params.name_regex = req.query.name_regex;
      nameQueries.push('nodes.tags -> \'name\' ' + comparison + ' \'{{name_regex}}\'');
    }

    if (nameQueries.length) queryArray.push('(' + nameQueries.join(' OR ') + ') AND');

    if (req.query.unit_code) {
      req.params.unit_code = '^' + req.query.unit_code.split(',').join('$|^') + '$';
      queryArray.push('nodes.tags -> \'nps:alphacode\' ~* \'{{unit_code}}\' AND');
    }

    queryArray.push('TRUE');
    queryArray.push(') nodes_in_query on pgs_current_nodes.id = nodes_in_query.node_id');
    var query = queryArray.join(' ');
    // console.log(query);

    if (true) { //TODO: eliminate invalid queries
      database(req, res).query(query, 'point', function(expressRes, dbResult) {
        if (dbResult && dbResult.data && dbResult.data.point && dbResult.data.point[0]) {
          // Remove the 'point' layer so the result is uniform with all the other results
          dbResult.data = apiFunctions.deleteEmptyTags(dbResult.data.point[0]);

          // TODO: limits need to be added to the point query

          apiFunctions.respond(expressRes, dbResult);
        }
      });
    } else {
      res.status({
        'statusCode': 501
      });
    }

  }
}];
