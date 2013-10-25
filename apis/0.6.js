var config = require('../config');
var queries = require('./apiSql');
var database = require('../tools/database');

var respond = function(res, dbResult){
  // Determines if there is an error and routes it to 'status', otherwise route the data to 'send'
  if (dbResult.error) {
    res.status(dbResult.error.code, dbResult.error.description, dbResult.details);
  } else {
    res.send(dbResult.data);
  }
};

// These are all the calls we need to handle
// http://wiki.openstreetmap.org/wiki/API_v0.6_(Archive)#Status
exports = module.exports = [{
  'name': 'GET capabilities',
  'description': 'Returns server capabilities.',
  'method': 'GET',
  'path': 'capabilities',
  'process': function(req, res) {
    res.send({'api':config.capabilities});
  }
},
{
  'name': 'GET node/#id',
  'description': 'Returns the XML for that node.',
  'method': 'GET',
  'path': 'node/:id',
  'process': function(req, res) {
    // Lookup the node in the database
    var query = queries.select.current.nodes.concat('WHERE', queries.where.current.id).join('\n');
    database(req, res).query(query, 'node', respond);
  }
},
{
  'name': 'PUT node/#id',
  'description': 'Updates the node, returns new version number.',
  'method': 'PUT',
  'path': 'node/:id',
  'process': function(req, res) {
    respond(res, database.node.update({'id': req.params.id}));
  }
},
{
  'name': 'DELETE node/#id',
  'description': 'Deletes the node, returns new version number(?).',
  'method': 'DELETE',
  'path': 'node/:id',
  'process': function(req, res) {
    respond(res, database.node.delete({'id': req.params.id}));
  }
},
{
  'name': 'PUT node/create',
  'description': 'Creates the node, returns new node number (new nodes always version=1?).',
  'method': 'PUT',
  'path': 'node/create',
  'process': function(req, res) {
    respond(res, database.node.create({'id': req.params.id}));
  }
},
{
  'name': 'GET node/#id/history',
  'description': 'Returns all versions of the node.',
  'method': 'GET',
  'path': 'node/:id/history',
  'process': function(req, res) {
    var query = queries.select.all.nodes.concat('WHERE', queries.where.all.id).join('\n');
    database(req, res).query(query, 'node', respond);
  }
},
{
  'name': 'GET node/#id/#version',
  'description': 'Returns the XML for that version of the node.',
  'method': 'GET',
  'path': 'node/:id/:version',
  'process': function(req, res) {
    respond(res, database.node.read({'id': req.params.id, 'version': req.params.version}));
  }
},
{
  'name': 'GET node/#id/ways',
  'description': 'Returns the XML for all ways that this node is part of.',
  'method': 'GET',
  'path': 'node/:id/ways',
  'process': function(req, res) {
    respond(res, database.node.read({'id': req.params.id, 'ways': true}));
  }
},
{
  'name': 'GET node/#id/relations',
  'description': 'Returns the XML for all relations that this node is part of.',
  'method': 'GET',
  'path': 'node/:id/relations',
  'process': function(req, res) {
    respond(res, database.node.read({'id': req.params.id, 'relations': true}));
  }
},
{
  'name': 'GET nodes?nodes=#id,#id,...',
  'description': 'Returns the XML for all given node numbers.',
  'method': 'GET',
  'path': 'nodes',
  'process': function(req, res) {
    respond(res, database.node.read({'nodes': req.params.nodes}));
  }
},
{
  'name': 'GET way/#id',
  'description': 'Returns the XML for that way.',
  'method': 'GET',
  'path': 'way/:id',
  'process': function(req, res) {
    var query = queries.select.current.ways.concat('WHERE', queries.where.current.id).join('\n');
    database(req, res).query(query, 'way', respond);
  }
},
{
  'name': 'PUT way/#id',
  'description': 'Updates the way, returns new version number.',
  'method': 'PUT',
  'path': 'way/:id',
  'process': function(req, res) {
    respond(res, database.way.update({'id': req.params.id}));
  }
},
{
  'name': 'DELETE way/#id',
  'description': 'Deletes the node, returns new version number(?).',
  'method': 'DELETE',
  'path': 'way/:id',
  'process': function(req, res) {
    respond(res, database.way.delete({'id': req.params.id}));
  }
},
{
  'name': 'PUT way/create',
  'description': 'Creates the way, returns new way number (new ways always version=1?).',
  'method': 'PUT',
  'path': 'way/create',
  'process': function(req, res) {
    respond(res, database.way.create({'id': req.params.id}));
  }
},
{
  'name': 'GET way/#id/history',
  'description': 'Returns all versions of the way.',
  'method': 'GET',
  'path': 'way/:id/history',
  'process': function(req, res) {
    var query = queries.select.all.ways.concat('WHERE', queries.where.all.id).join('\n');
    database(req, res).query(query, 'way', respond);
  }
},
{
  'name': 'GET way/#id/#version',
  'description': 'Returns the XML for that version of the way.',
  'method': 'GET',
  'path': 'way/:id/:version',
  'process': function(req, res) {
    respond(res, database.way.read({'id': req.params.id,'version': req.params.version}));
  }
},
{
  'name': 'GET way/#id/relations',
  'description': 'Returns the XML of all relations that this way is part of.',
  'method': 'GET',
  'path': 'way/:id/relations',
  'process': function(req, res) {
    return [req,res];
  }
},
{
  'name': 'GET way/#id/full',
  'description': 'Returns XML of a way and all its nodes.',
  'method': 'GET',
  'path': 'way/:id/full',
  'process': function(req, res) {
    respond(res, database.way.read({'id': req.params.id,'full': true}));
  }
},
{
  'name': 'GET ways?ways=#id,#id,...',
  'description': 'Returns XML of all numbered ways.',
  'method': 'GET',
  'path': 'ways',
  'process': function(req, res) {
    respond(res, database.way.read({'ways': req.params.ways}));
  }
},
{
  'name': 'GET relation/#id',
  'description': 'Returns the XML for that relation.',
  'method': 'GET',
  'path': 'relation/:id',
  'process': function(req, res) {
    var query = queries.select.current.relations.concat(queries.where.where, queries.where.current.id).join('\n');
    database(req, res).query(query, 'relation', respond);
  }
},
{
  'name': 'PUT relation/#id',
  'description': 'Updates the relation, returns new version number.',
  'method': 'PUT',
  'path': 'relation/:id',
  'process': function(req, res) {
    respond(res, database.relation.update({'id': req.params.id}));
  }
},
{
  'name': 'DELETE relation/#id',
  'description': 'Deletes the relation, returns new version number(?).',
  'method': 'DELETE',
  'path': 'relation/:id',
  'process': function(req, res) {
    respond(res, database.relation.delete({'id': req.params.id}));
  }
},
{
  'name': 'PUT relation/create',
  'description': 'Creates the relation, returns new relation number (always version=1?).',
  'method': 'PUT',
  'path': 'relation/create',
  'process': function(req, res) {
    respond(res, database.relation.create({'id': req.params.id}));
  }
},
{
  'name': 'GET relation/#id/history',
  'description': 'Returns all versions of the relation.',
  'method': 'GET',
  'path': 'relation/:id/history',
  'process': function(req, res) {
    var query = queries.select.all.relations.concat(queries.where.where, queries.where.all.id).join('\n');
    database(req, res).query(query, 'relation', respond);
  }
},
{
  'name': 'GET relation/#id/#version',
  'description': 'Returns the XML for that version of the relation.',
  'method': 'GET',
  'path': 'relation/:id/:version',
  'process': function(req, res) {
    respond(res, database.relation.read({'id': req.params.id, 'version': req.params.version}));
  }
},
{
  'name': 'GET relation/#id/relations',
  'description': 'Returns all relations that this relation appears in.',
  'method': 'GET',
  'path': 'relation/:id/relations',
  'process': function(req, res) {
    respond(res, database.relation.read({'id': req.params.id, 'relation': true}));
  }
},
{
  'name': 'GET relation/#id/full',
  'description': 'Returns all ways and nodes in this relation and relations directly members of this relation.',
  'method': 'GET',
  'path': 'relation/:id/full',
  'process': function(req, res) {
    respond(res, database.relation.read({'id': req.params.id, 'full': true}));
  }
},
{
  'name': 'GET relations?relations=#id,#id,...',
  'description': 'Returns the numbered relations.',
  'method': 'GET',
  'path': 'relations',
  'process': function(req, res) {
    respond(res, database.relation.read({'relaton': req.params.relations}));
  }
},
{
  'name': 'GET changeset/#id',
  'description': 'Returns the XML for that changeset.',
  'method': 'GET',
  'path': 'changeset/:id',
  'process': function(req, res) {
    var query = queries.select.changesets.concat(queries.where.where, queries.where.changeset.id).join('\n');
    database(req, res).query(query, 'changeset', respond);
  }
},
{
  'name': 'PUT changeset/#id',
  'description': 'Updates the changeset.',
  'method': 'PUT',
  'path': 'changeset/:id',
  'process': function(req, res) {
    respond(res, database.changeset.update({'id': req.params.id}));
  }
},
{
  'name': 'PUT changeset/create',
  'description': 'Creates the changeset, returns new changeset number (version=1?).',
  'method': 'PUT',
  'path': 'changeset/create',
  'process': function(req, res) {
    respond(res, database.changeset.create());
  }
},
{
  'name': 'PUT changeset/#id/close',
  'description': 'Marks a changeset closed, returns status only.',
  'method': 'PUT',
  'path': 'changeset/:id/close',
  'process': function(req, res) {
    respond(res, database.changeset.update({'id': req.params.id}));
  }
},
{
  'name': 'POST changeset/#id/upload',
  'description': 'Uploads a diff into a changeset transactionally.',
  'method': 'POST',
  'path': 'changeset/:id/upload',
  'process': function(req, res) {
    respond(res, database.changeset.update({'id': req.params.id}));
  }
},
{
  'name': 'GET changeset/#id/download',
  'description': 'Downloads all the changed elements in a changeset in OsmChange format.',
  'method': 'GET',
  'path': 'changeset/:id/download',
  'process': function(req, res) {
    respond(res, database.changeset.read({'id': req.params.id, 'download': true}));
  }
},
{
  'name': 'POST changeset/#id/expand_bbox',
  'description': 'Inserts a point into the bounding box of a changeset.',
  'method': 'POST',
  'path': 'changeset/:id/expand_bbox',
  'process': function(req, res) {
    respond(res, database.changeset.update({'id': req.params.id, 'expand_bbox': true}));
  }
},
{
  'name': 'GET changesets',
  'description': 'Queries changesets on bounding box, user or time range.',
  'method': 'GET',
  'path': 'changesets',
  'process': function(req, res) {
    // Not sure?
    respond(res, database.changeset.read({'query': req.params.query}));
  }
},
{
  'name': 'GET map',
  'description': 'Gets all the way, nodes and relations inside a bounding box.',
  'method': 'GET',
  'path': 'map',
  'process': function(req, res) {

    var queryList = [{
      'type': 'node',
      'query': queries.select.current.nodes.concat(
        'JOIN (',
        queries.select.current.nodesInWay,
        'JOIN (',
        queries.select.current.waysInBbox,
        ') ways_in_bbox ON current_way_nodes.way_id = ways_in_bbox.way_id',
        ') nodes_in_way ON current_nodes.id = nodes_in_way.node_id'
      ).join('\n')
    }, {
      'type': 'way',
      'query': queries.select.current.ways.concat(
        'JOIN (',
        queries.select.current.waysInBbox,
        ') ways_in_bbox ON current_ways.id = ways_in_bbox.way_id'
      ).join('\n')
    }, {
      'type': 'relation',
      'query': queries.select.current.relations.concat(
        'JOIN (',
        queries.select.current.relationsInBbox,
        'JOIN (',
        queries.select.current.waysInBbox,
        ') ways_in_bbox ON current_relation_members.member_id = ways_in_bbox.way_id',
        'WHERE lower(current_relation_members.member_type::text) = \'way\'',
        'UNION',
        queries.select.current.relationsInBbox,
        'JOIN (',
        queries.select.current.nodesInWay,
        'JOIN (',
        queries.select.current.waysInBbox,
        ') ways_in_bbox ON current_way_nodes.way_id = ways_in_bbox.way_id',
        ') nodes_in_way ON current_relation_members.member_id = nodes_in_way.node_id',
        'WHERE lower(current_relation_members.member_type::text) = \'node\'',
        ') all_relations_in_bbox ON current_relations.id = all_relations_in_bbox.relation_id'
      ).join('\n')
    }],
    responses = [],
    appendData = function(inRes, data) {
      var responseData = {};

      // If there's an error, report it immediately
      if (data.error && data.error.code && data.error.code === '500') {
        console.log(data.details);
        respond(inRes, data);
        responses = [];
      } else {
        // Add the data back to a result array
        responses.push(data);
        if (responses.length >= queryList.length) {
          for (var record in responses) {
            for (var obj in responses[record].data) {
              responseData[obj] = responses[record].data[obj];
            }
          }
          respond(inRes,{'data': responseData});
        }
      }

    };

    req.params.minLon = req.query.bbox.split(',')[0]; //'-75.5419922';
    req.params.minLat = req.query.bbox.split(',')[1]; //'39.7832127';
    req.params.maxLon = req.query.bbox.split(',')[2]; //'-75.5364990';
    req.params.maxLat = req.query.bbox.split(',')[3]; //'39.7874339';

    for (var queryIndex in queryList) {
      database(req, res).query(queryList[queryIndex].query, queryList[queryIndex].type, appendData);
    }

  }
},
{
  'name': 'GET trackpoints',
  'description': 'Gets paginated trackpoints within a bounding box.',
  'method': 'GET',
  'path': 'trackpoints',
  'process': function(req, res) {
    // Paginate, trackpoints, not sure?
    respond(res, database.all.read({'bbox': req.params.bbox}));
  }
},
{
  'name': 'GET changes',
  'description': 'Returns all changes within a given time period.',
  'method': 'GET',
  'path': 'changes',
  'process': function(req, res) {
    // How is this different from changesets?
    respond(res, database.changesets.read({'time_period': req.params.timePeriod}));
  }
}];
