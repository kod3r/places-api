// Determines whether to use the 0.6 API or the pgsnapshot API based on the query

var api06 = require('./0.6'),
pgsnapshot = require('./pgsnapshot');

var combineCalls = function(){
  var callArray = [], calls = {};

  // Look through all the calls in 0.6 and make a list
  for (var i=0; i < api06.length; i++) {
    calls[api06[i].method + '_' + api06[i].path] = api06[i];
  }
  // Loop through the calls in pgsnapshot and overwrite the ones that are in 0.6, or add new ones
  for (var j=0; j < pgsnapshot.length; j++) {
    /*var newPgs = pgsnapshot[j];
    newPgs.path = 'pgs/' + pgsnapshot[j].path;
    calls[newPgs.method + '_' + newPgs.path] = newPgs;*/
    calls[pgsnapshot[j].method + '_' + pgsnapshot[j].path] = pgsnapshot[j];
  }
  for (var call in calls) {
    callArray.push(calls[call]);
  }
  return callArray;
};

exports = module.exports = combineCalls();
