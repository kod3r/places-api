var express = require('express'),
    poiApi = require('poi-api'),
    path = require('path');

// Set the environment variables
var app = express();
app.set('port', process.env.PORT || 3000);

// OSM API
app.use('/api', poiApi.routes());

// oauth (prob move this into poi-api soon!
app.use('/oauth', poiApi.oauth());

// iD Editor
app.use(express.static(path.join(__dirname, '/node_modules/iD')));

app.listen(app.get('port'));
console.log('Node.js server listening on port ' + app.get('port'));
