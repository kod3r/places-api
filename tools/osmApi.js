var config = require('../config');
//    apiWrapper = require('./apiWrapper');

// This will be its own function that talks to the database
var database = {
  node: {
    'read': function(id) {return dbProcess('read', 'node', id);}
  },
  way: {
    'read': function(id) {return dbProcess('read', 'way', id);}
  },
  relation: {
    'read': function(id) {return dbProcess('read', 'relation', id);}
  },
  changeset: {
    'read': function(id) {return dbProcess('read', 'changeset', id);}
  }
};

var respond = function(res, dbResult){
  if (dbResult.error) {
    res.status(dbResult.error.code, dbResult.error.description);
  } else {
    res.send(dbResult.data);
  }
};

var dbProcess = function(method, type, id) {
  var returnValue = {
    data: {},
    error: null
  };

  // Run the database call

  // If it was successful
  if (true) {
    if (method === 'read' && type === 'node') {
      returnValue.data = {
        node: {
          'id': id,
          'lat': 40,
          'lon': -75,
          'changeset': 12,
          'user': 'fred',
          'version': 1,
          'uid': 38487,
          'visible': true,
          'timestamp': '2009-10-31T12:34:49Z',
          'tag': [{
            'k': 'note',
            'v': 'Just a node',
          },{
            'k': 'note2',
            'v': 'Just a node2'
          }]
        }
      }
    }
    if (method === 'read' && type === 'way') {
      returnValue.data = {
        way: {
          'id': id,
          'changeset': 12,
          'user': 'fred',
          'version': 1,
          'uid': 38487,
          'visible': true,
          'timestamp': '2009-10-31T12:34:49Z',
          'tag': [
            {'k': 'admin_level', 'v': '9'},
            {'k': 'boundary', 'v': 'administrative'}
          ],
          'nd': [
            {'ref': 17262},
            {'ref': 17265},
            {'ref': 17268}
          ]
        }
      };
    }
    if (method === 'read' && type === 'changeset') {
      returnValue.data = {
        changeset: {
          'id': id,
          'user': 'fred',
          'uid': 38487,
          'created_at': '2009-10-31T12:34:49Z',
          'closed_at': '2009-10-31T12:34:49Z',
          'open': false,
          'min_lat': '39.11',
          'min_lon': '-104.11',
          'max_lat': '39.12',
          'max_lon': '-104.10',
          'tag': [
            {'k': 'comment', 'v': 'best changeset ever'},
            {'k': 'created_by', 'v': 'NPS poiApi'}
          ],
        }
      };
    }
  } else {
      returnValue.error = {'code': '404', 'description': 'That doesn\'t exist!'};
  }
  return returnValue;
};

  // These are all the calls we need to handle
  // http://wiki.openstreetmap.org/wiki/API_v0.6_(Archive)#Status
  exports.apiCalls = [
  {
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
      respond(res, database.node.read(req.params.id));
    }
  },
  {
    'name': 'PUT node/#id',
    'description': 'Updates the node, returns new version number.',
    'method': 'PUT', 
    'path': 'node/:id', 
    'process': function(req, res) {
      res.send({'api':config.capabilities});
    }
  },
  {
    'name': 'DELETE node/#id',
    'description': 'Deletes the node, returns new version number(?).',
    'method': 'DELETE', 
    'path': 'node/:id', 
    'process': function(req, res) {
      res.send({'api':config.capabilities});
    }
  },
  {
    'name': 'PUT node/create',
    'description': 'Creates the node, returns new node number (new nodes always version=1?).',
    'method': 'PUT', 
    'path': 'node/create', 
    'process': function(req, res) {
      res.send({'api':config.capabilities});
    }
  },
  {
    'name': 'GET node/#id/history',
    'description': 'Returns all versions of the node.',
    'method': 'GET', 
    'path': 'node/:id/history', 
    'process': function(req, res) {
      res.send({'api':config.capabilities});
    }
  },
  {
    'name': 'GET node/#id/#version',
    'description': 'Returns the XML for that version of the node.',
    'method': 'GET', 
    'path': 'node/:id/:version', 
    'process': function(req, res) {
      res.send({'api':config.capabilities});
    }
  },
  {
    'name': 'GET node/#id/ways',
    'description': 'Returns the XML for all ways that this node is part of.',
    'method': 'GET', 
    'path': 'node/:id/ways', 
    'process': function(req, res) {
      res.send({'api':config.capabilities});
    }
  },
  {
    'name': 'GET node/#id/relations',
    'description': 'Returns the XML for all relations that this node is part of.',
    'method': 'GET', 
    'path': 'node/:id/relations', 
    'process': function(req, res) {
      res.send({'api':config.capabilities});
    }
  },
  {
    'name': 'GET nodes?nodes=#id,#id,...',
    'description': 'Returns the XML for all given node numbers.',
    'method': 'GET', 
    'path': 'nodes', 
    'process': function(req, res) {
      res.send({'api':config.capabilities});
    }
  },
  {
    'name': 'GET way/#id',
    'description': 'Returns the XML for that way.',
    'method': 'GET', 
    'path': 'way/:id', 
    'process': function(req, res) {
      // Lookup the node in the database
      respond(res, database.way.read(req.params.id));    }
  },
  {
    'name': 'PUT way/#id',
    'description': 'Updates the way, returns new version number.',
    'method': 'PUT', 
    'path': 'way/:id', 
    'process': function(req, res) {
      res.send({'api':config.capabilities});
    }
  },
  {
    'name': 'DELETE way/#id',
    'description': 'Deletes the node, returns new version number(?).',
    'method': 'DELETE', 
    'path': 'way/:id', 
    'process': function(req, res) {
      res.send({'api':config.capabilities});
    }
  },
  {
    'name': 'PUT way/create',
    'description': 'Creates the way, returns new way number (new ways always version=1?).',
    'method': 'PUT', 
    'path': 'way/create', 
    'process': function(req, res) {
      res.send({'api':config.capabilities});
    }
  },
  {
    'name': 'GET way/#id/history',
    'description': 'Returns all versions of the way.',
    'method': 'GET', 
    'path': 'way/:id/history', 
    'process': function(req, res) {
      res.send({'api':config.capabilities});
    }
  },
  {
    'name': 'GET way/#id/#version',
    'description': 'Returns the XML for that version of the way.',
    'method': 'GET', 
    'path': 'way/:id/:version', 
    'process': function(req, res) {
      res.send({'api':config.capabilities});
    }
  },
  {
    'name': 'GET way/#id/relations',
    'description': 'Returns the XML of all relations that this way is part of.',
    'method': 'GET', 
    'path': 'way/:id/relations', 
    'process': function(req, res) {
      res.send({'api':config.capabilities});
    }
  },
  {
    'name': 'GET way/#id/full',
    'description': 'Returns XML of a way and all its nodes.',
    'method': 'GET', 
    'path': 'way/:id/full', 
    'process': function(req, res) {
      res.send({'api':config.capabilities});
    }
  },
  {
    'name': 'GET ways?ways=#id,#id,...',
    'description': 'Returns XML of all numbered ways.',
    'method': 'GET', 
    'path': 'ways', 
    'process': function(req, res) {
      res.send({'api':config.capabilities});
    }
  },
  {
    'name': 'GET relation/#id',
    'description': 'Returns the XML for that relation.',
    'method': 'GET', 
    'path': 'relation/:id', 
    'process': function(req, res) {
      res.send({'api':config.capabilities});
    }
  },
  {
    'name': 'PUT relation/#id',
    'description': 'Updates the relation, returns new version number.',
    'method': 'PUT', 
    'path': 'relation/:id', 
    'process': function(req, res) {
      res.send({'api':config.capabilities});
    }
  },
  {
    'name': 'DELETE relation/#id',
    'description': 'Deletes the relation, returns new version number(?).',
    'method': 'DELETE', 
    'path': 'relation/:id', 
    'process': function(req, res) {
      res.send({'api':config.capabilities});
    }
  },
  {
    'name': 'PUT relation/create',
    'description': 'Creates the relation, returns new relation number (always version=1?).',
    'method': 'PUT', 
    'path': 'relation/create', 
    'process': function(req, res) {
      res.send({'api':config.capabilities});
    }
  },
  {
    'name': 'GET relation/#id/history',
    'description': 'Returns all versions of the relation.',
    'method': 'GET', 
    'path': 'relation/:id/history', 
    'process': function(req, res) {
      res.send({'api':config.capabilities});
    }
  },
  {
    'name': 'GET relation/#id/#version',
    'description': 'Returns the XML for that version of the relation.',
    'method': 'GET', 
    'path': 'relation/:id/:version', 
    'process': function(req, res) {
      res.send({'api':config.capabilities});
    }
  },
  {
    'name': 'GET relation/#id/relations',
    'description': 'Returns all relations that this relation appears in.',
    'method': 'GET', 
    'path': 'relation/:id/relations', 
    'process': function(req, res) {
      res.send({'api':config.capabilities});
    }
  },
  {
    'name': 'GET relation/#id/full',
    'description': 'Returns all ways and nodes in this relation and relations directly members of this relation.',
    'method': 'GET', 
    'path': 'relation/:id/full', 
    'process': function(req, res) {
      res.send({'api':config.capabilities});
    }
  },
  {
    'name': 'GET relations?relations=#id,#id,...',
    'description': 'Returns the numbered relations.',
    'method': 'GET', 
    'path': 'relations', 
    'process': function(req, res) {
      res.send({'api':config.capabilities});
    }
  },
  {
    'name': 'GET changeset/#id',
    'description': 'Returns the XML for that changeset.',
    'method': 'GET', 
    'path': 'changeset/:id', 
    'process': function(req, res) {
      respond(res, database.changeset.read(req.params.id));
    }
  },
  {
    'name': 'PUT changeset/#id',
    'description': 'Updates the changeset.',
    'method': 'PUT', 
    'path': 'changeset/:id', 
    'process': function(req, res) {
      res.send({'api':config.capabilities});
    }
  },
  {
    'name': 'PUT changeset/create',
    'description': 'Creates the changeset, returns new changeset number (version=1?).',
    'method': 'PUT', 
    'path': 'changeset/create', 
    'process': function(req, res) {
      res.send({'api':config.capabilities});
    }
  },
  {
    'name': 'PUT changeset/#id/close',
    'description': 'Marks a changeset closed, returns status only.',
    'method': 'PUT', 
    'path': 'changeset/:id/close', 
    'process': function(req, res) {
      res.send({'api':config.capabilities});
    }
  },
  {
    'name': 'POST changeset/#id/upload',
    'description': 'Uploads a diff into a changeset transactionally.',
    'method': 'POST', 
    'path': 'changeset/:id/upload', 
    'process': function(req, res) {
      res.send({'api':config.capabilities});
    }
  },
  {
    'name': 'GET changeset/#id/download',
    'description': 'Downloads all the changed elements in a changeset in OsmChange format.',
    'method': 'GET', 
    'path': 'changeset/:id/download', 
    'process': function(req, res) {
      res.send({'api':config.capabilities});
    }
  },
  {
    'name': 'POST changeset/#id/expand_bbox',
    'description': 'Inserts a point into the bounding box of a changeset.',
    'method': 'POST', 
    'path': 'changeset/:id/expand_bbox', 
    'process': function(req, res) {
      res.send({'api':config.capabilities});
    }
  },
  {
    'name': 'GET changesets',
    'description': 'Queries changesets on bounding box, user or time range.',
    'method': 'GET', 
    'path': 'changesets', 
    'process': function(req, res) {
      res.send({'api':config.capabilities});
    }
  },
  {
    'name': 'GET map',
    'description': 'Gets all the way, nodes and relations inside a bounding box.',
    'method': 'GET', 
    'path': 'map', 
    'process': function(req, res) {
      res.send({'api':config.capabilities});
    }
  },
  {
    'name': 'GET trackpoints',
    'description': 'Gets paginated trackpoints within a bounding box.',
    'method': 'GET', 
    'path': 'trackpoints', 
    'process': function(req, res) {
      res.send({'api':config.capabilities});
    }
  },
  {
    'name': 'GET changes',
    'description': 'Returns all changes within a given time period.',
    'method': 'GET', 
    'path': 'changes', 
    'process': function(req, res) {
      res.send({'api':config.capabilities});
    }
  }
  ];
