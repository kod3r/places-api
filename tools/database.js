var pg = require('pg');

var splitHstore = function(hstore) {
  var returnValue = [];

  hstore.split(', ').map(function (tag) {
    var tags = tag.split('=>');
    returnValue.push({'k': tags[0].replace(/"$|^"/g, ''), 'v': tags[1].replace(/"$|^"/g, '')});
  });

  return returnValue;
},
parseResults = function (results) {
  var returnValue = {node: {}};

  results.fields.map(function(field){
    if (results.rows[0][field.name]) {
      if (field.dataTypeID === 25846 ) {
        // hstore
        returnValue.node[field.name] = splitHstore(results.rows[0][field.name]);
      } else if (field.dataTypeID === 1184 ) {
        // timestamp
        returnValue.node[field.name] = results.rows[0][field.name].toISOString();
      } else {
        // Text or something
        returnValue.node[field.name] = results.rows[0][field.name].toString();
      }
    }
  });

  //  returnValue.test = results;
  return returnValue;
},
dbProcess = function(req, res, method, type, fields, callback) {
  // Run the database call
  var runQuery = function(query) {
    var queryData = {};
    var conString = 'postgres://username:password@server/database_name';
    var client = new pg.Client(conString);
    client.connect(function(err) {
      if (err) {
        queryData.error = err;
        callback(res, queryData);
        console.log('1');
      } else {
        client.query(query, function(err, results) {
          queryData.error = err;
          queryData.data = parseResults(results);
          callback(res, queryData);
        });
      }
    });
  };

  if (method === 'read') {
    var queryString = 'SELECT s.id, \'true\' as visible, ST_Y(s.geom) as lat, ST_X(s.geom) as lon, s.changeset_id as changeset, users.name as user, s.version, s.user_id as iud, s.tstamp AT TIME ZONE \'UTC\' as timestamp, s.tags as tag FROM '+type+'s s JOIN users on s.user_id = users.id WHERE s.id = '+fields.id+';';
    console.log(queryString);
    runQuery(queryString);
  }

  // If it was successful
  /*if (true) {
    if (method === 'read && type === 'node') {
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
};
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
}*/
};

exports = module.exports = function() {
  // This will be its own function that talks to the database

  var crud = ['create', 'read', 'update', 'delete'],
  dataTypes = ['node', 'way', 'relation', 'changeset'],
  returnValue = {},
  databaseFunction = function(crudValue, dataType) {return function(req, res, fields, callback) {return dbProcess(req, res, crudValue, dataType, fields, callback);};},
  createCrud = function(dataType) {
    var crudList = {};
    crud.map(function(crudValue) {
      crudList[crudValue] = databaseFunction(crudValue, dataType);
    });
    return crudList;
  };

  dataTypes.map(function(dataType) {
    returnValue[dataType] = createCrud(dataType);
  });

  return returnValue;
}();


