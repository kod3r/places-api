var pg = require('pg');
var config = require('../config');

exports = module.exports = function(req, res) {

  var databaseTools = {
    database: function (callback) {
      var connectionString = [
        'postgres://',
        config.database.username,
        ':',
        config.database.password,
        '@',
        config.database.address,
        '/',config.database.name
      ].join('');
      pg.connect(connectionString, callback);
    },
    addParams: function (query, type) {
      // TODO: This should use handlebars or something like it
      var newQuery = query,
      re = function(name) {return new RegExp('{{'+name+'}}','g');},
      param;
      for (param in req.params) {
        newQuery = newQuery.replace(re(param), req.params[param]);
      }
      newQuery = newQuery.replace(re('&type&'), type);
      //console.log(newQuery);
      return newQuery;
    },
    query: function(query, type, callback) {
      var queryResult = [],
      startTime = new Date();
      console.log('starting ' + type);
      databaseTools.database(function(err, client, done) {
        if (err) {
          queryResult.error = {'code': '500'};
          queryResult.details = err;
          callback(res, queryResult);
        } else {
          client.query(databaseTools.addParams(query, type), function(err, results) {
            if (err) {
              queryResult.error = {'code': '500'};
              queryResult.details = err;
            } else {
              console.log('finished ' + type + ' after: ' + (new Date() - startTime) + 'ms');
              queryResult.data = databaseTools.parse(results, type);
            }
            callback(res, queryResult);
            done();
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
        return json;
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


