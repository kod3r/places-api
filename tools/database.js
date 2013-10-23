var pg = require('pg');
//var config = require('../config');

exports = module.exports = function(req, res) {

  var databaseTools = {
    database: function () {
      var connectionString = 'postgres://osm:osm@10.147.146.121/osm_de_api';
      return new pg.Client(connectionString);
    }(),
    addParams: function (query) {
      // TODO: This should use handlebars or something like it
      var newQuery = query,
      re = function(name) {return new RegExp('{{'+name+'}}','g');};
      for (var param in req.params) {
        newQuery = newQuery.replace(re(param), req.params[param]);
      }
      return newQuery;
    },
    query: function(query, type, callback) {
      console.log('a', type);
      var queryResult = [];
      databaseTools.database.connect(function(err) {
        if (err) {
          queryResult.error = {'code': '500'};
          queryResult.details = err;
          callback(res, queryResult);
        } else {
          databaseTools.database.query(databaseTools.addParams(query), function(err, results) {
            if (err) {
              queryResult.error = {'code': '500'};
              queryResult.details = err;
            } else {
              queryResult.data = databaseTools.parse(results, type);
            }
            callback(res, queryResult);
          });
        }
      });
    },
    translateField: {
      '17987': function (hstore) {
        //hstore
        var returnValue = [];

        hstore.split('", "').map(function (tag) {
          var tags = tag.split('=>');
          returnValue.push({'k': tags[0].replace(/"$|^"/g, ''), 'v': tags[1].replace(/"$|^"/g, '')});
        });

        return returnValue;
      },
      '25846': function(hstore) {return databaseTools.translateField['17987'](hstore);},
      '114': function(json) {
        // json
        var returnValue = [], row, k;
        if( Object.prototype.toString.call( json ) === '[object Object]' ) {
          for (k in json) {
            row = {'k': k, 'v': json[k]};
            returnValue.push(row);
          }
        } else if ( Object.prototype.toString.call( json ) === '[object Array]' ) {
          for (k in json) {
            row = {'ref': json[k]};
            returnValue.push(row);
          }
        } else {
          returnValue = json;
        }
        return returnValue;
      },
      '1184': function (timestamp){
        // timestamp
        return timestamp.toISOString().replace('.000','');
      },
      '1016': function (ints) {
        //Array of ints
        var returnValue = [];

        ints.toString().split(',').map(function (val) {
          returnValue.push({'ref': val});
        });

        return returnValue;
      }
    },
    parse: function(results, type) {
      var returnValue = {}, returnRow;
      returnValue[type] = [];

      results.rows.map(function(row) {
        returnRow = {};
        results.fields.map(function(field){
          if (row[field.name]) {
            if (databaseTools.translateField[field.dataTypeID]) {
              returnRow[field.name] = databaseTools.translateField[field.dataTypeID](row[field.name]);
            } else {
              returnRow[field.name] = row[field.name].toString();
            }
          }
        });
        returnValue[type].push(returnRow);
      });

      //      returnValue.test = results;
      return returnValue;
    }
  };

  return {'query': databaseTools.query};
};


