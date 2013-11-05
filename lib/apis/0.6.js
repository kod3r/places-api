var config = require('../../config'),
Q = require('q'),
xmlJs = require('xmljs_translator'),
queries = require('./apiSql'),
database = require('../database'),
respond = function(res, dbResult){
  var fields = 0,
  emptyFields = 0;
  // Check for results
  if (dbResult.data) {
    for (var field in dbResult.data) {
      fields++;
      if (dbResult.data[field].length <= 0) {
        emptyFields++;
      }
    }
  }
  if (!dbResult.data || emptyFields === fields) {
    dbResult.error = dbResult.error ? dbResult.error : {'code': 404, 'description': 'No Data Returned', 'details': null};
  }

  // Determines if there is an error and routes it to 'status', otherwise route the data to 'send'
  if (dbResult.error) {
    if (dbResult.details) {
      dbResult.details.errorMessage = dbResult.details.message;
    }
    res.status({'statusCode': dbResult.error.code, 'description': dbResult.error.description, 'details': dbResult.details});
  } else {
    res.send(dbResult.data);
  }
},
multiRespond = function(queryList, callback){
  //TODO: replace this with Q
  var responses = [],
  responded = false,
  processResponse = function(res, dbResult) {
    var responseData = {};

    // If there's an error, report it immediately
    if (dbResult.error && dbResult.error.code && dbResult.error.code === '500' && !responded) {
      callback(res, dbResult);
      responded = true;
      responses = [];
    } else {
      // Add the data back to a result array
      responses.push(dbResult);

      // Check if we're ready to response to the browser
      if (responses.length >= queryList.length && !responded) {
        for (var record in responses) {
          for (var obj in responses[record].data) {
            responseData[obj] = responses[record].data[obj];
          }
        }
        callback(res,{'data': responseData});
        responded = true;
      }
    }
  };

  return processResponse;
},
readXmlReq = function(req, callback) {
  var xmlData = '',
  calledback = false;
  req.setEncoding('utf8');
  req.on('data', function(data) {
    xmlData += data;
  });

  req.on('error', function(err) {
    if (!calledback) {
      callback(err, null);
      calledback = true;
    }
  });

  req.on('end', function() {
    if (!calledback) {
      callback(null, xmlJs.jsonify(xmlData));
      calledback = true;
    }
  });
},
valToArray = function(value) {
  // Since single objects will show up as not being in an array
  if( Object.prototype.toString.call( value ) === '[object Array]' ) {
    return value;
  } else if (value) {
    return [value];
  } else {
    return [];
  }
},
readOsmChange = {
  changeset: function(data, callback) {
    console.log('changeset 1');
    var changesetRequest = {},
    functionList = [],
    returnData = {},
    runCommand = function(type, change) {
      var deferred = Q.defer(), query;

      change.tag = valToArray(change.tag);

      if (type === 'node') {
        // TODO: move these calculations to the database
        // TODO: Make this lookup into an object instead of an if tree as soon as the previous todo is done
        change.lon = Math.round(change.lon * 10000000);
        change.lat = Math.round(change.lat * 10000000);
        query = 'SELECT to_json(upsert_node(\'{{id}}\', \'{{lat}}\', \'{{lon}}\', \'{{changeset}}\', \'{{visible}}\', \'{{tag}}\')) AS node';
      } else if (type === 'way') {
        query = 'SELECT to_json(upsert_way(\'{{id}}\', \'{{changeset}}\', \'{{visible}}\', \'{{nd}}\', \'{{tag}}\')) AS way';
      } else if (type === 'relation') {
        query = 'SELECT to_json(upsert_relation(\'{{id}}\', \'{{changeset}}\', \'{{visible}}\', \'{{member}}\', \'{{tag}}\')) AS relation';
      }
      console.log('a', query);
      query = database().addParams(query, type, change);
      console.log('b', query);

      database().query(query, type, function(_, queryRes) {
        if (queryRes && queryRes.data && queryRes.data[type]) {
          console.log('****', JSON.stringify(queryRes));
          if (!returnData[type]) {returnData[type] = [];}
          queryRes.data[type].map(function(record) {
            returnData[type].push(record[type]);
          });
          deferred.resolve(queryRes);
        } else {
          console.log('rejected', queryRes);
          deferred.reject(queryRes);
        }

      });
      return deferred.promise;
    },
    processRequests = function(type) {
      var action, changeIndex, change;
      functionList = [];
      reassignNodes(type, changesetRequest, returnData);
      for (action in changesetRequest) {
        if (changesetRequest[action][type]) {
          changesetRequest[action][type] = valToArray(changesetRequest[action][type]);
          for (changeIndex in changesetRequest[action][type]) {
            change = changesetRequest[action][type][changeIndex];
            change.visible = action !== 'delete';
            functionList.push(runCommand(type, change));
          }
        }
      }
      return Q.all(functionList);
    },
    reassignNodes = function(type, changeset, referenceData) {
      var translationTable = {},
      neededRefs = {
        'way': 'node',
        'relation': 'way'
      };
      if (returnData && returnData[neededRefs[type]]) {
        returnData[neededRefs[type]].map(function(newRef) {
          translationTable[newRef.old_id] = newRef.new_id;
        });
      }

      // Loop through that ugly object and update the nodes!
      for (var action in changesetRequest) {
        if (type === 'way' && changesetRequest[action].way) {
          changesetRequest[action].way = valToArray(changesetRequest[action].way);
          for (var way in changesetRequest[action].way) {
            if (changesetRequest[action].way[way].nd) {
              changesetRequest[action].way[way].nd = valToArray(changesetRequest[action].way[way].nd);
              for (var node in changesetRequest[action].way[way].nd) {
                if (changesetRequest[action].way[way].nd[node].ref && translationTable[changesetRequest[action].way[way].nd[node].ref]) {
                  changesetRequest[action].way[way].nd[node].node_id = translationTable[changesetRequest[action].way[way].nd[node].ref];
                } else {
                  changesetRequest[action].way[way].nd[node].node_id = changesetRequest[action].way[way].nd[node].ref;
                }
                changesetRequest[action].way[way].nd[node].sequence_id = node;
              }
            }
          }
        }
        if (type === 'relation' && changesetRequest[action].relation) {
          changesetRequest[action].relation = valToArray(changesetRequest[action].relation);
          for (var relation in changesetRequest[action].relation) {
            if (changesetRequest[action].relation[relation].member) {
              changesetRequest[action].relation[relation].member = valToArray(changesetRequest[action].relation[relation].member);
              for (var member in changesetRequest[action].relation[relation].member) {
                if (changesetRequest[action].relation[relation].member[member]) {
                  changesetRequest[action].relation[relation].member[member].member_id = changesetRequest[action].relation[relation].member[member].ref;
                  if (changesetRequest[action].relation[relation].member[member].type === 'node' && translationTable[changesetRequest[action].relation[relation].member[member].ref]) {
                    changesetRequest[action].relation[relation].member[member].member_id = translationTable[changesetRequest[action].relation[relation].member[member].ref];
                  } else if (changesetRequest[action].relation[relation].member[member].type === 'way' && wayTranslationTable[changesetRequest[action].relation[relation].member[member].ref]) {
                    changesetRequest[action].relation[relation].member[member].member_id = wayTranslationTable[changesetRequest[action].relation[relation].member[member].ref];
                  }
                  changesetRequest[action].relation[relation].member[member].sequence_id = member;
                  changesetRequest[action].relation[relation].member[member].member_role = changesetRequest[action].relation[relation].member[member].role;
                  changesetRequest[action].relation[relation].member[member].member_type = changesetRequest[action].relation[relation].member[member].type;
                  changesetRequest[action].relation[relation].member[member].member_type = capFirst(changesetRequest[action].relation[relation].member[member].member_type);
                }
              }
            } else {
              changesetRequest[action].relation[relation].member = [];
            }
          }
        }
      }
    },
    capFirst = function(str) {
      return str.substr(0, 1).toUpperCase() + str.substr(1);
    };

    // Assign the values to the request object
    if (data && data.osmChange && data.osmChange.create && data.osmChange.modify && data.osmChange.delete) {
      changesetRequest.create = (data.osmChange.create);
      changesetRequest.modify = (data.osmChange.modify);
      changesetRequest.delete = (data.osmChange.delete);

      processRequests('node').then(function() {
        processRequests('way').then(function() {
          processRequests('relation').then(function() {
            callback({'data': returnData});
          });
        });
      });

    } else {
      callback({error: 'ERROR'});
    }
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
    var query = queries.select.current.nodes.concat('WHERE', queries.where.current.node.id).join('\n');
    database(req, res).query(query, 'node', respond);
  }
},
{
  'name': 'PUT node/#id',
  'description': 'Updates the node, returns new version number.',
  'method': 'PUT',
  'path': 'node/:id',
  'process': function(req, res) {
    res.status({'statusCode': 501});
  }
},
{
  'name': 'DELETE node/#id',
  'description': 'Deletes the node, returns new version number(?).',
  'method': 'DELETE',
  'path': 'node/:id',
  'process': function(req, res) {
    res.status({'statusCode': 501});
  }
},
{
  'name': 'PUT node/create',
  'description': 'Creates the node, returns new node number (new nodes always version=1?).',
  'method': 'PUT',
  'path': 'node/create',
  'process': function(req, res) {
    res.status({'statusCode': 501});
  }
},
{
  'name': 'GET node/#id/history',
  'description': 'Returns all versions of the node.',
  'method': 'GET',
  'path': 'node/:id/history',
  'process': function(req, res) {
    var query = queries.select.all.nodes.concat('WHERE', queries.where.all.node.id).join('\n');
    database(req, res).query(query, 'node', respond);
  }
},
{
  'name': 'GET node/#id/ways',
  'description': 'Returns the XML for all ways that this node is part of.',
  'method': 'GET',
  'path': 'node/:id/ways',
  'process': function(req, res) {
    var query = queries.select.current.ways.concat(
      'JOIN (',
      queries.select.current.waysWithNode,
      ') ways_with_node ON current_ways.id = ways_with_node.way_id'
    ).join('\n');
    database(req, res).query(query, 'way', respond);
  }
},
{
  'name': 'GET node/#id/relations',
  'description': 'Returns the XML for all relations that this node is part of.',
  'method': 'GET',
  'path': 'node/:id/relations',
  'process': function(req, res) {
    var query = queries.select.current.relations.concat(
      'JOIN (',
      queries.select.current.relationsWithNode,
      ') relations_with_node ON current_relations.id = relations_with_node.relation_id'
    ).join('\n');
    database(req, res).query(query, 'relation', respond);
  }
},
{
  'name': 'GET node/#id/#version',
  'description': 'Returns the XML for that version of the node.',
  'method': 'GET',
  'path': 'node/:id/:version',
  'process': function(req, res) {
    var query = queries.select.all.nodes.concat('WHERE', queries.where.all.node.id, 'AND', queries.where.all.node.version).join('\n');
    database(req, res).query(query, 'node', respond);
  }
},
{
  'name': 'GET nodes?nodes=#id,#id,...',
  'description': 'Returns the XML for all given node numbers.',
  'method': 'GET',
  'path': 'nodes',
  'process': function(req, res) {
    var query = queries.select.current.nodes.concat('WHERE', 'current_nodes.id IN (\'{{nodes}}\')').join('\n');
    req.params.nodes = req.query.nodes.split(',').join('\',\'');
    database(req, res).query(query, 'node', respond);
  }
},
{
  'name': 'GET way/#id',
  'description': 'Returns the XML for that way.',
  'method': 'GET',
  'path': 'way/:id',
  'process': function(req, res) {
    var query = queries.select.current.ways.concat('WHERE', queries.where.current.way.id).join('\n');
    database(req, res).query(query, 'way', respond);
  }
},
{
  'name': 'PUT way/#id',
  'description': 'Updates the way, returns new version number.',
  'method': 'PUT',
  'path': 'way/:id',
  'process': function(req, res) {
    res.status({'statusCode': 501});
  }
},
{
  'name': 'DELETE way/#id',
  'description': 'Deletes the node, returns new version number(?).',
  'method': 'DELETE',
  'path': 'way/:id',
  'process': function(req, res) {
    res.status({'statusCode': 501});
  }
},
{
  'name': 'PUT way/create',
  'description': 'Creates the way, returns new way number (new ways always version=1?).',
  'method': 'PUT',
  'path': 'way/create',
  'process': function(req, res) {
    res.status({'statusCode': 501});
  }
},
{
  'name': 'GET way/#id/history',
  'description': 'Returns all versions of the way.',
  'method': 'GET',
  'path': 'way/:id/history',
  'process': function(req, res) {
    var query = queries.select.all.ways.concat('WHERE', queries.where.all.way.id).join('\n');
    database(req, res).query(query, 'way', respond);
  }
},
{
  'name': 'GET way/#id/relations',
  'description': 'Returns the XML of all relations that this way is part of.',
  'method': 'GET',
  'path': 'way/:id/relations',
  'process': function(req, res) {
    var query = queries.select.current.relations.concat(
      'JOIN (',
      queries.select.current.relationsWithWay,
      ') relations_with_way ON current_relations.id = relations_with_way.relation_id'
    ).join('\n');
    database(req, res).query(query, 'relation', respond);
  }
},
{
  'name': 'GET way/#id/full',
  'description': 'Returns XML of a way and all its nodes.',
  'method': 'GET',
  'path': 'way/:id/full',
  'process': function(req, res) {
    var queryList = [{
      'type': 'way',
      'query': queries.select.current.ways.concat('WHERE', queries.where.current.way.id).join('\n')
    },
    {
      'type': 'node',
      'query': queries.select.current.nodes.concat(
        'JOIN (',
        queries.select.current.nodesInWay,
        'WHERE current_way_nodes.way_id = \'{{id}}\'',
        ') nodes_in_way ON nodes_in_way.node_id = current_nodes.id'
      ).join('\n')
    }],
    responses = multiRespond(queryList, respond);

    for (var queryIndex in queryList) {
      database(req, res).query(queryList[queryIndex].query, queryList[queryIndex].type, responses);
    }
  }
},
{
  'name': 'GET way/#id/#version',
  'description': 'Returns the XML for that version of the way.',
  'method': 'GET',
  'path': 'way/:id/:version',
  'process': function(req, res) {
    var query = queries.select.all.ways.concat('WHERE', queries.where.all.way.id, 'AND', queries.where.all.way.version).join('\n');
    database(req, res).query(query, 'way', respond);
  }
},
{
  'name': 'GET ways?ways=#id,#id,...',
  'description': 'Returns XML of all numbered ways.',
  'method': 'GET',
  'path': 'ways',
  'process': function(req, res) {
    var query = queries.select.current.ways.concat('WHERE', 'current_ways.id IN (\'{{ways}}\')').join('\n');
    req.params.ways = req.query.ways.split(',').join('\',\'');
    database(req, res).query(query, 'way', respond);
  }
},
{
  'name': 'GET relation/#id',
  'description': 'Returns the XML for that relation.',
  'method': 'GET',
  'path': 'relation/:id',
  'process': function(req, res) {
    var query = queries.select.current.relations.concat('WHERE', queries.where.current.relation.id).join('\n');
    database(req, res).query(query, 'relation', respond);
  }
},
{
  'name': 'PUT relation/#id',
  'description': 'Updates the relation, returns new version number.',
  'method': 'PUT',
  'path': 'relation/:id',
  'process': function(req, res) {
    res.status({'statusCode': 501});
  }
},
{
  'name': 'DELETE relation/#id',
  'description': 'Deletes the relation, returns new version number(?).',
  'method': 'DELETE',
  'path': 'relation/:id',
  'process': function(req, res) {
    res.status({'statusCode': 501});
  }
},
{
  'name': 'PUT relation/create',
  'description': 'Creates the relation, returns new relation number (always version=1?).',
  'method': 'PUT',
  'path': 'relation/create',
  'process': function(req, res) {
    res.status({'statusCode': 501});
  }
},
{
  'name': 'GET relation/#id/history',
  'description': 'Returns all versions of the relation.',
  'method': 'GET',
  'path': 'relation/:id/history',
  'process': function(req, res) {
    var query = queries.select.all.relations.concat('WHERE', queries.where.all.relation.id).join('\n');
    database(req, res).query(query, 'relation', respond);
  }
},
{
  'name': 'GET relation/#id/relations',
  'description': 'Returns all relations that this relation appears in.',
  'method': 'GET',
  'path': 'relation/:id/relations',
  'process': function(req, res) {
    var query = queries.select.current.relations.concat(
      'JOIN (',
      queries.select.current.relationsWithRelation,
      ') relations_with_relation ON current_relations.id = relations_with_relation.relation_id'
    ).join('\n');
    database(req, res).query(query, 'relation', respond);

  }
},
{
  'name': 'GET relation/#id/full',
  'description': 'Returns all ways and nodes in this relation and relations directly members of this relation.',
  'method': 'GET',
  'path': 'relation/:id/full',
  'process': function(req, res) {
    var queryList = [{
      'type': 'relation',
      'query': queries.select.current.relations.concat(
        'JOIN (',
        queries.select.current.relationsWithRelation,
        'UNION',
        'SELECT \'{{id}}\' as relation_id',
        ') relations_with_relation ON current_relations.id = relations_with_relation.relation_id'
      ).join('\n')
    }, {
      'type': 'way',
      'query': queries.select.current.ways.concat(
        'JOIN (',
        queries.select.current.waysInRelation,
        ') waysInRelation ON current_ways.id = waysInRelation.way_id'
      ).join('\n')
    }, {
      'type': 'node',
      'query': queries.select.current.nodes_old.concat(
        'JOIN (',
        queries.select.current.nodesInRelation,
        'UNION',
        queries.select.current.nodesInWay,
        'JOIN (',
        queries.select.current.waysInRelation,
        ') ways_in_bbox ON current_way_nodes.way_id = ways_in_bbox.way_id',
        ') nodesInRelation ON current_nodes.id = nodesInRelation.node_id'
      ).join('\n')
    }],
    responses = multiRespond(queryList, respond);

    for (var queryIndex in queryList) {
      database(req, res).query(queryList[queryIndex].query, queryList[queryIndex].type, responses);
    }
  }
},
{
  'name': 'GET relation/#id/#version',
  'description': 'Returns the XML for that version of the relation.',
  'method': 'GET',
  'path': 'relation/:id/:version',
  'process': function(req, res) {
    var query = queries.select.all.relations.concat('WHERE', queries.where.all.relation.id, 'AND', queries.where.all.relation.version).join('\n');
    database(req, res).query(query, 'relation', respond);
  }
},
{
  'name': 'GET relations?relations=#id,#id,...',
  'description': 'Returns the numbered relations.',
  'method': 'GET',
  'path': 'relations',
  'process': function(req, res) {
    var query = queries.select.current.relations.concat('WHERE', 'current_relations.id IN (\'{{relations}}\')').join('\n');
    req.params.relations = req.query.relations.split(',').join('\',\'');
    database(req, res).query(query, 'relation', respond);
  }
},
{
  'name': 'PUT changeset/create',
  'description': 'Creates the changeset, returns new changeset number (version=1?).',
  'method': 'PUT',
  'path': 'changeset/create',
  'process': function(req, res) {
    readXmlReq(req, function(error, data) {
      if (error) {
        respond(res,{'error': {'code': 503, 'description': 'PUT Data Read Error'}});
      } else {
        // Can we make a new changeset with this?
        if (data.osm && data.osm && data.osm.changeset) {
          var query = 'INSERT INTO changesets (user_id, created_at, closed_at, num_changes) VALUES (-1, now(), now(), 0) RETURNING id';
          database(res, req).query(query, 'id', function(x, result) {
            res.send(result.data.id[0].id, 'txt');
            // Also add the tags to the database
            if (data.osm.changeset.tag) {
              var tags = valToArray(data.osm.changeset.tag);
              for (var tagIndex in tags) {
                query = 'INSERT INTO changeset_tags (changeset_id, k, v) VALUES (' + result.data.id[0].id + ', \'' + tags[tagIndex].k + '\', \'' + tags[tagIndex].v + '\')';
                database(res, req).query(query);
              }
            }
          });
        } else {
          respond(res,{'error': {'code': 502, 'description': 'Read Error', 'details': '3'}});
        }
      }
    });
  }
},
{
  'name': 'GET changeset/#id',
  'description': 'Returns the XML for that changeset.',
  'method': 'GET',
  'path': 'changeset/:id',
  'process': function(req, res) {
    var query = queries.select.all.changesets.concat('WHERE', queries.where.changeset.id).join('\n');
    database(req, res).query(query, 'changeset', respond);
  }
},
{
  'name': 'PUT changeset/#id',
  'description': 'Updates the changeset.',
  'method': 'PUT',
  'path': 'changeset/:id',
  'process': function(req, res) {
    res.status({'statusCode': 501});
  }
},
{
  'name': 'PUT changeset/#id/close',
  'description': 'Marks a changeset closed, returns status only.',
  'method': 'PUT',
  'path': 'changeset/:id/close',
  'process': function(req, res) {
    var query = 'UPDATE changesets SET closed_at = now() WHERE id = \'{{id}}\'';
    database(req, res).query(query, 'changeset', function() {
      res.status({'statusCode': 200});
    });
  }
},
{
  'name': 'POST changeset/#id/upload',
  'description': 'Uploads a diff into a changeset transactionally.',
  'method': 'POST',
  'path': 'changeset/:id/upload',
  'process': function(req, res) {
    readXmlReq(req, function(error, data) {
      readOsmChange.changeset(data, function(result) {
        console.log(result);
        if (result.data) {
          res.send(result.data, 'xml', {'wrapType' : 'diffResult'});
        } else {
          res.status({'statusCode': 400, 'details': result});
        }
      });
    });
  }
},
  {
    // http://wiki.openstreetmap.org/wiki/OsmChange
    'name': 'GET changeset/#id/download',
    'description': 'Downloads all the changed elements in a changeset in OsmChange format.',
    'method': 'GET',
    'path': 'changeset/:id/download',
    'process': function(req, res) {
      res.status({'statusCode': 501});
    }
  },
  {
    'name': 'POST changeset/#id/expand_bbox',
    'description': 'Inserts a point into the bounding box of a changeset.',
    'method': 'POST',
    'path': 'changeset/:id/expand_bbox',
    'process': function(req, res) {
      res.status({'statusCode': 501});
    }
  },
  {
    'name': 'GET changesets',
    'description': 'Queries changesets on bounding box, user or time range.',
    'method': 'GET',
    'path': 'changesets',
    'process': function(req, res) {
      // Not sure?
      res.status({'statusCode': 501});
    }
  },
  {
    'name': 'GET map',
    'description': 'Gets all the way, nodes and relations inside a bounding box.',
    'method': 'GET',
    'path': 'map',
    'process': function(req, res) {

      var query = 'SELECT bounds, node, way, relation FROM getBbox(\'{{minLat}}\', \'{{minLon}}\', \'{{maxLat}}\', \'{{maxLon}}\')';

      req.params.minLon = req.query.bbox.split(',')[0]; //'-75.5419922';
      req.params.minLat = req.query.bbox.split(',')[1]; //'39.7832127';
      req.params.maxLon = req.query.bbox.split(',')[2]; //'-75.5364990';
      req.params.maxLat = req.query.bbox.split(',')[3]; //'39.7874339';

      // Move this function up top?
      // TODO: implement this for all queries from the view
      var deleteEmptyTags = function(input) {
        var output = {};
        for (var type in input) {
          output[type] = input[type];
          for (var index in output[type]) {
            if (output[type][index] && output[type][index].hasOwnProperty('tag') && output[type][index].tag === null) {
              delete output[type][index].tag;
            }
          }
        }
        return output;
      };

      database(req, res).query(query, 'map', function(expressRes, dbResult) {
        if (dbResult && dbResult.data && dbResult.data.map && dbResult.data.map[0]) {
          // Remove the 'map' layer so the result is uniform with all the other results
          dbResult.data = deleteEmptyTags(dbResult.data.map[0]);
        }
        respond(expressRes, dbResult);
      });
    }
  },
  {
    'name': 'GET trackpoints',
    'description': 'Gets paginated trackpoints within a bounding box.',
    'method': 'GET',
    'path': 'trackpoints',
    'process': function(req, res) {
      // Paginate, trackpoints, not sure?
      res.status({'statusCode': 501});
    }
  },
  {
    'name': 'GET changes',
    'description': 'Returns all changes within a given time period.',
    'method': 'GET',
    'path': 'changes',
    'process': function(req, res) {
      // How is this different from changesets?
      res.status({'statusCode': 501});
    }
  }];
