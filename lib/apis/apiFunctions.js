/* jshint camelcase: false */

var Q = require('q'),
xmlJs = require('xmljs_translator'),
database = require('../database')('api'),
queries = require('./apiSql'),
osmAuth = require('../oauth/oauthFunctions');

exports = module.exports = {
  respond: function(res, dbResult){
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
  readXmlReq: function(req, callback) {
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
  valToArray: function(value) {
    // Since single objects will show up as not being in an array
    if( Object.prototype.toString.call( value ) === '[object Array]' ) {
      return value;
    } else if (value) {
      return [value];
    } else {
      return [];
    }
  },
  readOsmChange: {
    changeset: function(data, callback) {
      var changesetRequest = {},
      functionList = [],
      returnData = {},
      runCommand = function(type, change) {
        var deferred = Q.defer(), queryList, query;

        change.tag = exports.valToArray(change.tag);
        if (change.lon) {change.lon = Math.round(change.lon * 10000000);}
        if (change.lat) {change.lat = Math.round(change.lat * 10000000);}

        queryList = {
          'changeset': 'SELECT upsert_changeset(\'{{id}}\', \'{{user_id}}\', \'{{tag}}\') AS changeset',
          'node': 'SELECT to_json(upsert_node(\'{{id}}\', \'{{lat}}\', \'{{lon}}\', \'{{changeset}}\', \'{{visible}}\', \'{{tag}}\')) AS node',
          'way': 'SELECT to_json(upsert_way(\'{{id}}\', \'{{changeset}}\', \'{{visible}}\', \'{{nd}}\', \'{{tag}}\')) AS way',
          'relation': 'SELECT to_json(upsert_relation(\'{{id}}\', \'{{changeset}}\', \'{{visible}}\', \'{{member}}\', \'{{tag}}\')) AS relation'
        };

        if (queryList[type]) {
          query = database().addParams(queryList[type], type, change);

          database().query(query, type, function(_, queryRes) {
            if (queryRes && queryRes.data && queryRes.data[type]) {
              if (!returnData[type]) {returnData[type] = [];}
              queryRes.data[type].map(function(record) {
                returnData[type].push(record[type]);
              });
              deferred.resolve(queryRes);
            } else {
              deferred.reject(queryRes);
            }
          });
        } else {
          deferred.reject('Invalid Type');
        }

        return deferred.promise;
      },
      processRequests = function(type) {
        var action, changeIndex, change;
        functionList = [];
        changesetRequest = reassignNodes(type, changesetRequest, returnData);
        for (action in changesetRequest) {
          if (changesetRequest[action] && changesetRequest[action][type]) {
            changesetRequest[action][type] = exports.valToArray(changesetRequest[action][type]);
            for (changeIndex in changesetRequest[action][type]) {
              change = changesetRequest[action][type][changeIndex];
              change.visible = action !== 'delete';
              functionList.push(runCommand(type, change));
            }
          }
        }
        return Q.all(functionList);
      },
      reassignNodes  = function(type, changeset, referenceData) {
        //// TODO: Move this out of the function if we want
        var translationTable = {},
        neededRefs = {
          'way': 'node',
          'relation': 'way'
        };
        if (referenceData && returnData[neededRefs[type]]) {
          referenceData[neededRefs[type]].map(function(newRef) {
            translationTable[newRef.old_id] = newRef.new_id;
          });
        }

        // Loop through that ugly object and update the nodes and ways!
        for (var action in changeset) {
          if (type === 'way' && changeset[action] && changeset[action].way) {
            changeset[action].way = exports.valToArray(changeset[action].way);
            for (var way in changeset[action].way) {
              if (changeset[action].way[way].nd) {
                changeset[action].way[way].nd = exports.valToArray(changeset[action].way[way].nd);
                for (var node in changeset[action].way[way].nd) {
                  if (changeset[action].way[way].nd[node].ref && translationTable[changeset[action].way[way].nd[node].ref]) {
                    changeset[action].way[way].nd[node].node_id = translationTable[changeset[action].way[way].nd[node].ref];
                  } else {
                    changeset[action].way[way].nd[node].node_id = changeset[action].way[way].nd[node].ref;
                  }
                  changeset[action].way[way].nd[node].sequence_id = node;
                }
              }
            }
          }
          if (type === 'relation' && changeset[action] && changeset[action].relation) {

            changeset[action].relation = exports.valToArray(changeset[action].relation);
            for (var relation in changeset[action].relation) {
              if (changeset[action].relation[relation].member) {
                changeset[action].relation[relation].member = exports.valToArray(changeset[action].relation[relation].member);
                for (var member in changeset[action].relation[relation].member) {
                  if (changeset[action].relation[relation].member[member]) {
                    changeset[action].relation[relation].member[member].member_id = changeset[action].relation[relation].member[member].ref;
                    if (changeset[action].relation[relation].member[member].type === 'node' && translationTable[changeset[action].relation[relation].member[member].ref]) {
                      changeset[action].relation[relation].member[member].member_id = translationTable[changeset[action].relation[relation].member[member].ref];
                    } else if (changeset[action].relation[relation].member[member].type === 'way' && translationTable[changeset[action].relation[relation].member[member].ref]) {
                      changeset[action].relation[relation].member[member].member_id = translationTable[changeset[action].relation[relation].member[member].ref];
                    }
                    changeset[action].relation[relation].member[member].sequence_id = member;
                    changeset[action].relation[relation].member[member].member_role = changeset[action].relation[relation].member[member].role;
                    changeset[action].relation[relation].member[member].member_type = changeset[action].relation[relation].member[member].type;
                    changeset[action].relation[relation].member[member].member_type = capFirst(changeset[action].relation[relation].member[member].member_type);
                  }
                }
              } else {
                changeset[action].relation[relation].member = [];
              }
            }
          }
        }
        return changeset;
      },
      capFirst = function(str) {
        return str.substr(0, 1).toUpperCase() + str.substr(1);
      };

      // Assign the values to the request object
      if (data && data.osmChange) { // && data.osmChange.create && data.osmChange.modify && data.osmChange.delete) {
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

      } else if (data && data.osm && data.osm && data.osm.changeset) {
        // Upsert Changeset
        changesetRequest.create = (data.osm);
        if (!changesetRequest.create.changeset.id || changesetRequest.create.changeset.id === '0') {
          changesetRequest.create.changeset.id = '-1';
        } 
        if (!changesetRequest.create.changeset.user_id) {
          changesetRequest.create.changeset.user_id = '-1';
        }
        processRequests('changeset').then(function() {
          returnData = {'changeset': returnData.changeset[0]};
          callback({'data': returnData});
        });
      } else {
        callback({error: 'ERROR'});
      }
    }
  },
  deleteEmptyTags: function(input) {
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
  },
  queryMultipleElements: function(req, res, type) {
    //http://wiki.openstreetmap.org/wiki/API_v0.6#Multi_fetch:_GET_.2Fapi.2F0.6.2F.5Btypes.7Cways.7Crelations.5D.3F.23parameters
    var types = type + 's', typeList, query;
    if (req.query[types] && !isNaN(req.query[types].replace(/,/g, ''))) {
      typeList = req.query[types].split(',');
      query = queries.select.current[types].concat('WHERE');
      typeList.map(function(typeId, typeIndex) {
        if (typeId && !isNaN(typeId)) {
          query.push('api_current_' + types + '.id = \'{{' + type + typeIndex + '}}\'');
          query.push('OR');
        }
      });
      query.pop();
      query = query.join('\n');
      database(req, res).query(query, type, exports.respond);
    } else {
      exports.respond(res, {'error': {'code': 404, 'description': 'Not a valid path'}});
    }
  },
  auth: {
    oauth: function (req, res, callback) {
      osmAuth.authReq(req, function(data) {
        if (data.valid && data.userId) {
          req.params.uid = data.userId;
          callback(req, res);
        } else {
          res.status({'statusCode': 401});
        }
      });
    },
    basic: function (req, res, unauthorized, callback) {
      //get the user and pass
      osmAuth.authReqBasic(req, function(data) {
        if (data.valid && data.userId) {
          req.params.uid = data.userId;
          callback(req, res);
        } else {
          unauthorized();
        }
      });
    }
  }

};
