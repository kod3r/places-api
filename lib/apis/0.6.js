/* jshint camelcase: false */

var config = require('../../config'),
  queries = require('./apiSql'),
  database = require('../database')('api'),
  apiFunctions = require('./apiFunctions'),
  tileMath = require('../tileMath');

// These are all the calls we need to handle
// http://wiki.openstreetmap.org/wiki/API_v0.6_(Archive)#Status
exports = module.exports = [{
  'name': 'GET capabilities',
  'description': 'Returns server capabilities.',
  'method': 'GET',
  'path': 'capabilities',
  'auth': apiFunctions.auth,
  'process': function(req, res) {
    res.send({
      'api': config.capabilities
    });
  }
}, {
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
  'name': 'PUT node/#id',
  'description': 'Updates the node, returns new version number.',
  'method': 'PUT',
  'path': 'node/:id(\\d+)',
  'process': function(req, res) {
    res.status({
      'statusCode': 501
    });
  }
}, {
  'name': 'DELETE node/#id',
  'description': 'Deletes the node, returns new version number(?).',
  'method': 'DELETE',
  'path': 'node/:id(\\d+)',
  'process': function(req, res) {
    res.status({
      'statusCode': 501
    });
  }
}, {
  'name': 'PUT node/create',
  'description': 'Creates the node, returns new node number (new nodes always version=1?).',
  'method': 'PUT',
  'path': 'node/create',
  'process': function(req, res) {
    res.status({
      'statusCode': 501
    });
  }
}, {
  'name': 'GET node/#id/history',
  'description': 'Returns all versions of the node.',
  'method': 'GET',
  'path': 'node/:id(\\d+)/history',
  'process': function(req, res) {
    var query = queries.select.all.nodes.concat('WHERE', queries.where.all.node.id).join('\n');
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
      ') ways_with_node ON api_current_ways.id = ways_with_node.way_id'
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
      ') relations_with_node ON api_current_relations.id = relations_with_node.relation_id'
    ).join('\n');
    database(req, res).query(query, 'relation', apiFunctions.respond);
  }
}, {
  'name': 'GET node/#id/#version',
  'description': 'Returns the XML for that version of the node.',
  'method': 'GET',
  'path': 'node/:id(\\d+)/:version(\\d+)',
  'process': function(req, res) {
    if (!isNaN(req.params.version)) {
      var query = queries.select.all.nodes.concat('WHERE', queries.where.all.node.id, 'AND', queries.where.all.node.version).join('\n');
      database(req, res).query(query, 'node', apiFunctions.respond);
    } else {
      apiFunctions.respond(res, {
        'error': {
          'code': 404,
          'description': 'Not a valid path'
        }
      });
    }
  }
}, {
  'name': 'GET nodes?nodes=#id,#id,...',
  'description': 'Returns the XML for all given node numbers.',
  'method': 'GET',
  'path': 'nodes',
  'process': function(req, res) {
    apiFunctions.queryMultipleElements(req, res, 'node');
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
  'name': 'PUT way/#id',
  'description': 'Updates the way, returns new version number.',
  'method': 'PUT',
  'path': 'way/:id(\\d+)',
  'process': function(req, res) {
    res.status({
      'statusCode': 501
    });
  }
}, {
  'name': 'DELETE way/#id',
  'description': 'Deletes the node, returns new version number(?).',
  'method': 'DELETE',
  'path': 'way/:id(\\d+)',
  'process': function(req, res) {
    res.status({
      'statusCode': 501
    });
  }
}, {
  'name': 'PUT way/create',
  'description': 'Creates the way, returns new way number (new ways always version=1?).',
  'method': 'PUT',
  'path': 'way/create',
  'process': function(req, res) {
    res.status({
      'statusCode': 501
    });
  }
}, {
  'name': 'GET way/#id/history',
  'description': 'Returns all versions of the way.',
  'method': 'GET',
  'path': 'way/:id(\\d+)/history',
  'process': function(req, res) {
    var query = queries.select.all.ways.concat('WHERE', queries.where.all.way.id).join('\n');
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
      ') relations_with_way ON api_current_relations.id = relations_with_way.relation_id'
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
        'WHERE current_way_nodes.way_id = \'{{id}}\'',
        ') nodes_in_way ON nodes_in_way.node_id = api_current_nodes.id'
      ).join('\n')
    }];

    database(req, res).query(queryList, null, apiFunctions.respond);
  }
}, {
  'name': 'GET way/#id/#version',
  'description': 'Returns the XML for that version of the way.',
  'method': 'GET',
  'path': 'way/:id(\\d+)/:version(\\d+)',
  'process': function(req, res) {
    if (!isNaN(req.params.version)) {
      var query = queries.select.all.ways.concat('WHERE', queries.where.all.way.id, 'AND', queries.where.all.way.version).join('\n');
      database(req, res).query(query, 'way', apiFunctions.respond);
    } else {
      apiFunctions.respond(res, {
        'error': {
          'code': 404
        }
      });
    }
  }
}, {
  'name': 'GET ways?ways=#id,#id,...',
  'description': 'Returns XML of all numbered ways.',
  'method': 'GET',
  'path': 'ways',
  'process': function(req, res) {
    apiFunctions.queryMultipleElements(req, res, 'way');
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
  'name': 'PUT relation/#id',
  'description': 'Updates the relation, returns new version number.',
  'method': 'PUT',
  'path': 'relation/:id(\\d+)',
  'process': function(req, res) {
    res.status({
      'statusCode': 501
    });
  }
}, {
  'name': 'DELETE relation/#id',
  'description': 'Deletes the relation, returns new version number(?).',
  'method': 'DELETE',
  'path': 'relation/:id(\\d+)',
  'process': function(req, res) {
    res.status({
      'statusCode': 501
    });
  }
}, {
  'name': 'PUT relation/create',
  'description': 'Creates the relation, returns new relation number (always version=1?).',
  'method': 'PUT',
  'path': 'relation/create',
  'process': function(req, res) {
    res.status({
      'statusCode': 501
    });
  }
}, {
  'name': 'GET relation/#id/history',
  'description': 'Returns all versions of the relation.',
  'method': 'GET',
  'path': 'relation/:id(\\d+)/history',
  'process': function(req, res) {
    var query = queries.select.all.relations.concat('WHERE', queries.where.all.relation.id).join('\n');
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
      ') relations_with_relation ON api_current_relations.id = relations_with_relation.relation_id'
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
        ') relations_with_relation ON api_current_relations.id = relations_with_relation.relation_id'
      ).join('\n')
    }, {
      'type': 'way',
      'query': queries.select.current.ways.concat(
        'JOIN (',
        queries.select.current.waysInRelation,
        ') waysInRelation ON api_current_ways.id = waysInRelation.way_id'
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
        ') ways_in_bbox ON current_way_nodes.way_id = ways_in_bbox.way_id',
        ') nodesInRelation ON api_current_nodes.id = nodesInRelation.node_id'
      ).join('\n')
    }];
    database(req, res).query(queryList, null, apiFunctions.respond);
  }
}, {
  'name': 'GET relation/#id/#version',
  'description': 'Returns the XML for that version of the relation.',
  'method': 'GET',
  'path': 'relation/:id(\\d+)/:version(\\d+)',
  'process': function(req, res) {
    if (!isNaN(req.params.version)) {
      var query = queries.select.all.relations.concat('WHERE', queries.where.all.relation.id, 'AND', queries.where.all.relation.version).join('\n');
      database(req, res).query(query, 'relation', apiFunctions.respond);
    } else {
      apiFunctions.respond(res, {
        'error': {
          'code': 404
        }
      });
    }
  }
}, {
  'name': 'GET relations?relations=#id,#id,...',
  'description': 'Returns the numbered relations.',
  'method': 'GET',
  'path': 'relations',
  'process': function(req, res) {
    apiFunctions.queryMultipleElements(req, res, 'relations');
  }
}, {
  'name': 'PUT changeset/create',
  'description': 'Creates the changeset, returns new changeset number (version=1?).',
  'method': 'PUT',
  'path': 'changeset/create',
  'auth': apiFunctions.auth,
  'process': function(req, res) {
    apiFunctions.readXmlReq(req, function(error, data) {
      // Add in the user id from the auth step
      console.log('changing uid', req.params.uid);
      data.osm.changeset.user_id = req.params.uid;
      apiFunctions.readOsmChange.changeset(data, function(result) {
        if (result) {
          res.send(result.data.changeset[0].id, 'txt');
        } else {
          res.status({
            'statusCode': 400,
            'details': result
          });
        }
      });
    });
  }
}, {
  'name': 'GET changeset/#id',
  'description': 'Returns the XML for that changeset.',
  'method': 'GET',
  'path': 'changeset/:id(\\d+)',
  'process': function(req, res) {
    if (!isNaN(req.params.id)) {
      var query = queries.select.all.changesets.concat('WHERE', queries.where.changeset.id).join('\n');
      database(req, res).query(query, 'changeset', apiFunctions.respond);
    } else {
      apiFunctions.respond(res, {
        'error': {
          'code': 404,
          'description': 'Not a valid path'
        }
      });
    }

    // TODO: Make sure id is a number
  }
}, {
  'name': 'PUT changeset/#id',
  'description': 'Updates the changeset.',
  'method': 'PUT',
  'path': 'changeset/:id(\\d+)',
  'auth': apiFunctions.auth,
  'process': function(req, res) {
    // JOSM uses this
    apiFunctions.readXmlReq(req, function(error, data) {
      apiFunctions.readOsmChange.changeset(data, function(result) {
        if (result.data) {
          res.send(result.data, 'xml');
        } else {
          res.status({
            'statusCode': 400,
            'details': result
          });
        }
      });
    });
  }
}, {
  'name': 'PUT changeset/#id/close',
  'description': 'Marks a changeset closed, returns status only.',
  'method': 'PUT',
  'path': 'changeset/:id(\\d+)/close',
  'auth': apiFunctions.auth,
  'process': function(req, res) {
    var query = 'UPDATE changesets SET closed_at = now() WHERE id = \'{{id}}\'';
    database(req, res).query(query, 'changeset', function() {
      res.send('', 'txt');
    });
  }
}, {
  'name': 'POST changeset/#id/upload',
  'description': 'Uploads a diff into a changeset transactionally.',
  'method': 'POST',
  'path': 'changeset/:id(\\d+)/upload',
  'auth': apiFunctions.auth,
  'process': function(req, res) {
    apiFunctions.readXmlReq(req, function(error, data) {
      apiFunctions.readOsmChange.changeset(data, function(result) {
        if (result.data) {
          res.send(result.data, 'xml', {
            'wrapType': 'diffResult'
          });
        } else {
          res.status({
            'statusCode': 400,
            'details': result
          });
        }
      });
    });
  }
}, {
  // http://wiki.openstreetmap.org/wiki/OsmChange
  'name': 'GET changeset/#id/download',
  'description': 'Downloads all the changed elements in a changeset in OsmChange format.',
  'method': 'GET',
  'path': 'changeset/:id(\\d+)/download',
  'process': function(req, res) {
    res.status({
      'statusCode': 501
    });
  }
}, {
  'name': 'POST changeset/#id/expand_bbox',
  'description': 'Inserts a point into the bounding box of a changeset.',
  'method': 'POST',
  'path': 'changeset/:id(\\d+)/expand_bbox',
  'process': function(req, res) {
    res.status({
      'statusCode': 501
    });
  }
}, {
  'name': 'GET changesets',
  'description': 'Queries changesets on bounding box, user or time range.',
  'method': 'GET',
  'path': 'changesets',
  'process': function(req, res) {
    // Not sure? //JOSM uses this
    res.status({
      'statusCode': 200
    });
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
  'name': 'GET trackpoints',
  'description': 'Gets paginated trackpoints within a bounding box.',
  'method': 'GET',
  'path': 'trackpoints',
  'process': function(req, res) {
    // Paginate, trackpoints, not sure?
    res.status({
      'statusCode': 501
    });
  }
}, {
  'name': 'GET changes',
  'description': 'Returns all changes within a given time period.',
  'method': 'GET',
  'path': 'changes',
  'process': function(req, res) {
    // How is this different from changesets?
    res.status({
      'statusCode': 501
    });
  }
}, {
  'name': 'GET user details',
  'description': 'Returns the user details from the OSM server.',
  'method': 'GET',
  'path': 'user/details',
  'auth': apiFunctions.auth,
  'process': function(req, res) {
    // TODO: make a view for this (I don't know if we really want/need it
    var query = 'SELECT id, display_name, (\'{"href": "\' || image_file_name || \'"}\')::json as img, replace((creation_time || \'Z\'),\' \',\'T\') as account_created FROM users WHERE id = \'{{uid}}\'';
    database(req, res).query(query, 'user', apiFunctions.respond);
  }
}, {
  'name': 'GET JSOM settings',
  'description': 'Returns the keys needed to connect the server using JOSM and OAuth.',
  'method': 'GET',
  'path': 'user/josm',
  'auth': apiFunctions.auth,
  'process': function(req, res) {
    // TODO: make a view for this (I don't know if we really want/need it
    var query = 'SELECT access_token as accessToken, access_token_secret as accessTokenSecret FROM sessions WHERE user_id = \'{{uid}}\' order by created_time desc limit 1';
    query = database().addParams(query, 'josm_settings', req.params);
    database().query(query, 'josm_settings', function(_, data) {
      if (data && data.data && data.data.josm_settings && data.data.josm_settings[0]) {
        var josm = data.data.josm_settings[0];
        josm.consumerKey = config.oauth.consumerKey;
        josm.consumerSecret = config.oauth.consumerSecret;
        josm.requestToken = req.protocol + '://' + req.get('host') + '/oauth/request_token';
        josm.accessToken = req.protocol + '://' + req.get('host') + '/oauth/access_token';
        josm.authorizeUrl = req.protocol + '://' + req.get('host') + '/oauth/authorize';
        res.send({
          'josm_settings': josm
        });
      } else {
        console.log(data, data.data.josm_settings);
        res.send({
          'Error': 'No OAuth exists for current user (' + req.params.uid + ')'
        });
      }
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
