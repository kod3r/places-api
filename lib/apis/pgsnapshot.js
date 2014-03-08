/* jshint camelcase: false */

var queries = require('./pgsSql'),
  database = require('../database')('pgs'),
  apiFunctions = require('./apiFunctions'),
  tileMath = require('../tileMath');

// This is a subset of calls that can use the pgsnapshot database for quicker processing
// http://wiki.openstreetmap.org/wiki/API_v0.6_(Archive)#Status
exports = module.exports = [{
  'name': 'GET node/#id',
  'description': 'Returns the XML for that node.',
  'method': 'GET',
  'path': 'node/:id(\\d+)',
  'process': function(req, res) {
    // Lookup the node in the database
    var query = queries.select.current.nodes.concat('WHERE', queries.where.current.node.id).join('\n');
    database(req, res).query(query, 'node', apiFunctions.respond);
  }
}, {
  'name': 'GET node/#id/ways',
  'description': 'Returns the XML for all ways that this node is part of.',
  'method': 'GET',
  'path': 'node/:id(\\d+)/ways',
  'process': function(req, res) {
    var query = queries.select.current.ways.concat(
      'JOIN (',
      queries.select.current.waysWithNode,
      ') ways_with_node ON pgs_current_ways.id = ways_with_node.way_id'
    ).join('\n');
    database(req, res).query(query, 'way', apiFunctions.respond);
  }
}, {
  'name': 'GET node/#id/relations',
  'description': 'Returns the XML for all relations that this node is part of.',
  'method': 'GET',
  'path': 'node/:id(\\d+)/relations',
  'process': function(req, res) {
    var query = queries.select.current.relations.concat(
      'JOIN (',
      queries.select.current.relationsWithNode,
      ') relations_with_node ON pgs_current_relations.id = relations_with_node.relation_id'
    ).join('\n');
    database(req, res).query(query, 'relation', apiFunctions.respond);
  }
}, {
  'name': 'GET way/#id',
  'description': 'Returns the XML for that way.',
  'method': 'GET',
  'path': 'way/:id(\\d+)',
  'process': function(req, res) {
    var query = queries.select.current.ways.concat('WHERE', queries.where.current.way.id).join('\n');
    database(req, res).query(query, 'way', apiFunctions.respond);
  }
}, {
  'name': 'GET way/#id/relations',
  'description': 'Returns the XML of all relations that this way is part of.',
  'method': 'GET',
  'path': 'way/:id(\\d+)/relations',
  'process': function(req, res) {
    var query = queries.select.current.relations.concat(
      'JOIN (',
      queries.select.current.relationsWithWay,
      ') relations_with_way ON pgs_current_relations.id = relations_with_way.relation_id'
    ).join('\n');
    database(req, res).query(query, 'relation', apiFunctions.respond);
  }
}, {
  'name': 'GET way/#id/full',
  'description': 'Returns XML of a way and all its nodes.',
  'method': 'GET',
  'path': 'way/:id(\\d+)/full',
  'process': function(req, res) {
    var queryList = [{
      'type': 'way',
      'query': queries.select.current.ways.concat('WHERE', queries.where.current.way.id).join('\n')
    }, {
      'type': 'node',
      'query': queries.select.current.nodes.concat(
        'JOIN (',
        queries.select.current.nodesInWay,
        'WHERE way_nodes.way_id = \'{{id}}\'',
        ') nodes_in_way ON nodes_in_way.node_id = pgs_current_nodes.id'
      ).join('\n')
    }];

    database(req, res).query(queryList, null, apiFunctions.respond);
  }
}, {
  'name': 'GET relation/#id',
  'description': 'Returns the XML for that relation.',
  'method': 'GET',
  'path': 'relation/:id(\\d+)',
  'process': function(req, res) {
    var query = queries.select.current.relations.concat('WHERE', queries.where.current.relation.id).join('\n');
    database(req, res).query(query, 'relation', apiFunctions.respond);
  }
}, {
  'name': 'GET relation/#id/relations',
  'description': 'Returns all relations that this relation appears in.',
  'method': 'GET',
  'path': 'relation/:id(\\d+)/relations',
  'process': function(req, res) {
    var query = queries.select.current.relations.concat(
      'JOIN (',
      queries.select.current.relationsWithRelation,
      ') relations_with_relation ON pgs_current_relations.id = relations_with_relation.relation_id'
    ).join('\n');
    database(req, res).query(query, 'relation', apiFunctions.respond);

  }
}, {
  'name': 'GET relation/#id/full',
  'description': 'Returns all ways and nodes in this relation and relations directly members of this relation.',
  'method': 'GET',
  'path': 'relation/:id(\\d+)/full',
  'process': function(req, res) {
    //TODO: Clean this up, somehow?
    var queryList = [{
      'type': 'relation',
      'query': queries.select.current.relations.concat(
        'JOIN (',
        queries.select.current.relationsWithRelation,
        'UNION',
        'SELECT \'{{id}}\' as relation_id',
        ') relations_with_relation ON pgs_current_relations.id = relations_with_relation.relation_id'
      ).join('\n')
    }, {
      'type': 'way',
      'query': queries.select.current.ways.concat(
        'JOIN (',
        queries.select.current.waysInRelation,
        ') waysInRelation ON pgs_current_ways.id = waysInRelation.way_id'
      ).join('\n')
    }, {
      'type': 'node',
      'query': queries.select.current.nodes.concat(
        'JOIN (',
        queries.select.current.nodesInRelation,
        'UNION',
        queries.select.current.nodesInWay,
        'JOIN (',
        queries.select.current.waysInRelation,
        ') ways_in_bbox ON way_nodes.way_id = ways_in_bbox.way_id',
        ') nodesInRelation ON pgs_current_nodes.id = nodesInRelation.node_id'
      ).join('\n')
    }];
    database(req, res).query(queryList, null, apiFunctions.respond);
  }
}, {
  'name': 'GET map',
  'description': 'Gets all the way, nodes and relations inside a bounding box.',
  'method': 'GET',
  'path': 'map',
  'process': function(req, res) {

    var query = 'SELECT bounds, node, way, relation, limits FROM getBbox(\'{{minLat}}\', \'{{minLon}}\', \'{{maxLat}}\', \'{{maxLon}}\', 5000)';

    req.params.minLon = req.query.bbox.split(',')[0]; //'-75.5419922';
    req.params.minLat = req.query.bbox.split(',')[1]; //'39.7832127';
    req.params.maxLon = req.query.bbox.split(',')[2]; //'-75.5364990';
    req.params.maxLat = req.query.bbox.split(',')[3]; //'39.7874339';

    // Move this function up top?
    database(req, res).query(query, 'map', function(expressRes, dbResult) {
      if (dbResult && dbResult.data && dbResult.data.map && dbResult.data.map[0]) {
        // Remove the 'map' layer so the result is uniform with all the other results
        dbResult.data = apiFunctions.deleteEmptyTags(dbResult.data.map[0]);

        // Check it we went over our limit
        if (dbResult.data.limits && dbResult.data.limits[0].reached) {
          dbResult = {
            'error': {
              'code': '509',
              'description': {
                'limit': dbResult.data.limits
              }
            }
          };
        } else if (dbResult.data.limits) {
          delete dbResult.data.limits;
        }
      }
      apiFunctions.respond(expressRes, dbResult);
    });
  }
}, {
  'name': 'GET tile extent',
  'description': 'Returns data from within the requested tile',
  'method': 'GET',
  'path': 'tile/:z(\\d+)/:x(\\d+)/:y(\\d+)',
  'process': function(req, res) {

    var query = 'SELECT bounds, node, way, relation, limits FROM getBbox(\'{{minLat}}\', \'{{minLon}}\', \'{{maxLat}}\', \'{{maxLon}}\', 2500)';

    req.params.x = parseInt(req.params.x, 10);
    req.params.y = parseInt(req.params.y, 10);
    req.params.z = parseInt(req.params.z, 10);
    req.params.minLon = tileMath.tile2long(req.params.x, req.params.z);
    req.params.minLat = tileMath.tile2lat(req.params.y + 1, req.params.z);
    req.params.maxLon = tileMath.tile2long(req.params.x + 1, req.params.z);
    req.params.maxLat = tileMath.tile2lat(req.params.y, req.params.z);

    // Move this function up top?
    database(req, res).query(query, 'map', function(expressRes, dbResult) {
      if (dbResult && dbResult.data && dbResult.data.map && dbResult.data.map[0]) {
        // Remove the 'map' layer so the result is uniform with all the other results
        dbResult.data = apiFunctions.deleteEmptyTags(dbResult.data.map[0]);

        // Check it we went over our limit
        if (dbResult.data.limits && dbResult.data.limits[0].reached) {
          dbResult = {
            'error': {
              'code': '509',
              'description': {
                'limit': dbResult.data.limits
              }
            }
          };
        } else if (dbResult.data.limits) {
          delete dbResult.data.limits;
        }
      }
      apiFunctions.respond(expressRes, dbResult);
    });
  }
}];
