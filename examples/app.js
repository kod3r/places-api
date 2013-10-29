var express = require('express'),
    poiApi = require('poi-api');
var path = require('path');

// Set the environment variables
var app = express();
app.set('port', process.env.PORT || 80);

// Link to the poiApt
app.use('/api', poiApi.routes());
app.use(express.static(path.join(__dirname, '/iD')));

app.listen(app.get('port'));
console.log('Node.js server listening on port ' + app.get('port'));
