
exports = module.exports = function() {
// This will be its own function that talks to the database

  var crud = ['create', 'read', 'update', 'delete'],
  dataTypes = ['node', 'way', 'relation', 'changeset'],
  returnValue = {},
  databaseFunction = function(crudValue, dataType) {return function(id) {return dbProcess(crudValue, dataType, id);};},
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

  console.log(returnValue);
  return returnValue;
}();

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
  }
  console.log(returnValue);
  return returnValue;
};


