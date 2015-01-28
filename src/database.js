var Bluebird = require('bluebird'),
  errorLogger = require('errorLogger'),
  pg = require('pg');

module.exports = function(dbtype, config) {
  if (!dbtype || !config || !config.database || !config.database[dbtype]) {
    errorLogger.debug('--dbtype error--', dbtype);
    throw 'invalid database type';
  }
  return function(req, res) {

    var databaseTools = {
      database: function(callback) {
        var connectionString = [
          'postgres://',
          config.database.username,
          ':',
          config.database.password,
          '@',
          config.database.address,
          '/',
          config.database[dbtype]
        ].join('');
        pg.connect(connectionString, callback);
      },
      addParams: function(query, type, params) {
        // TODO: This should use handlebars or something like it
        var newQuery = query,
          paramArray = [],
          re = function(name) {
            return new RegExp('\'{{' + name + '}}\'', 'g');
          },
          paramIndex, param;

        // Allow another set of params to be passed in
        if (req && req.params) {
          params = params || req.params;
        }

        for (paramIndex in params) {
          if (typeof(params[paramIndex]) === 'object') {
            // Allow JSON as a param
            param = JSON.stringify(params[paramIndex]);
          } else {
            param = params[paramIndex];
          }
          if (newQuery.search(re(paramIndex)) >= 0) {
            newQuery = newQuery.replace(re(paramIndex), '$' + (paramArray.push(param)));
          }
        }

        newQuery = newQuery.replace(re('&type&'), type);
        errorLogger.debug(newQuery);
        return {
          'query': newQuery,
          'queryParams': paramArray,
          'type': type
        };
      },
      runIndividualQuery: function(query, params, client, type) {
        return new Bluebird(function(resolve, reject) {
          var queryResult = {};
          var startTime = new Date();
          errorLogger.debug('Starting ' + type);
          errorLogger.debug('Query', query);
          errorLogger.debug('Params', params);
          client.query(query, params, function(err, results) {
            if (err) {
              errorLogger.debug('finished ' + type + ' with error after: ' + (new Date() - startTime) + 'ms');
              errorLogger.debug('error: ', err);
              errorLogger.debug('params: ', params);
              queryResult.error = {
                'code': '404'
              };
              queryResult.details = err;
              queryResult.details.query = query;
              queryResult.details.paramArray = params;
              reject(queryResult);
            } else {
              errorLogger.debug('finished ' + type + ' after: ' + (new Date() - startTime) + 'ms');
              queryResult.data = databaseTools.parse(results, type);
              resolve(queryResult);
            }
          });
        });
      },
      processResponse: function(dbResult) {
        var response = {};
        dbResult.map(function(thisResult) {
          for (var responseType in thisResult) {
            for (var dataType in thisResult[responseType]) {
              if (!response[responseType]) {
                response[responseType] = {};
              }
              if (!response[responseType][dataType]) {
                response[responseType][dataType] = [];
              }
              response[responseType][dataType] = response[responseType][dataType].concat(thisResult[responseType][dataType]);
            }
          }
        });
        return response;
      },
      query: function(query, type, callback) {
        var queryResult = {},
          paramQuery, requestList = [];
        databaseTools.database(function(err, client, done) {
          if (err) {
            queryResult.error = {
              'code': '500'
            };
            queryResult.details = err;
            if (callback) {
              callback(res, queryResult);
            }
          } else {
            // Allow an array of queries to be send
            if (Object.prototype.toString.call(query) !== '[object Array]') {
              query = [query];
            }
            query.map(function(thisQuery) {
              // Allow queries to come in with their parameters already set {query: '', queryParams: ''}
              if (typeof(thisQuery) === 'object' && thisQuery.query) {
                paramQuery = thisQuery;
              } else {
                paramQuery = databaseTools.addParams(thisQuery, type);
              }
              // If the query isn't already parameterized, parameterize it!
              if (!paramQuery.queryParams) {
                paramQuery = databaseTools.addParams(paramQuery.query, paramQuery.type);
              }
              requestList.push(databaseTools.runIndividualQuery(paramQuery.query, paramQuery.queryParams, client, paramQuery.type));
            });

            Bluebird.all(requestList).then(function(newResult) {
              done();
              if (callback) {
                callback(res, databaseTools.processResponse(newResult));
              }
            }).catch(function(e) {
              callback(res, e);
            });
          }

        });
      },
      translateField: {
        '17987': function(hstore) {
          //hstore
          var returnValue = [];

          hstore.split('", "').map(function(tag) {
            var tags = tag.split('=>');
            returnValue.push({
              'k': tags[0].replace(/"$|^"/g, ''),
              'v': tags[1].replace(/"$|^"/g, '')
            });
          });

          return returnValue;
        },
        '25846': function(hstore) {
          return databaseTools.translateField['17987'](hstore);
        },
        '114': function(json) {
          return json;
        },
        '1184': function(timestamp) {
          // timestamp
          return timestamp.toISOString().replace('.000', '');
        },
        '1016': function(ints) {
          //Array of ints
          var returnValue = [];

          ints.toString().split(',').map(function(val) {
            returnValue.push({
              'ref': val
            });
          });

          return returnValue;
        }
      },
      parse: function(results, type) {
        var returnValue = {},
          returnRow;
        returnValue[type] = [];

        results.rows.map(function(row) {
          returnRow = {};
          results.fields.map(function(field) {
            if (row[field.name] || typeof(row[field.name]) === 'boolean') {
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

    return {
      'query': databaseTools.query,
      'addParams': databaseTools.addParams
    };
  };
};
