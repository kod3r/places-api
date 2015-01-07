// Determines whether to use the 0.6 API or the pgsnapshot API based on the query
module.exports = function(config) {
  var calls = {},
    callArray = [],
    pgsnapshot = require('./pgsnapshot')(config),
    api06 = require('./0.6')(config);

  // Look through all the calls in 0.6 and make a list
  for (var i = 0; i < api06.length; i++) {
    calls[api06[i].method + '_' + api06[i].path] = api06[i];
  }
  // Loop through the calls in pgsnapshot and overwrite the ones that are in 0.6, or add new ones
  for (var j = 0; j < pgsnapshot.length; j++) {
    calls[pgsnapshot[j].method + '_' + pgsnapshot[j].path] = pgsnapshot[j];
  }
  for (var call in calls) {
    callArray.push(calls[call]);
  }
  return callArray;
};
