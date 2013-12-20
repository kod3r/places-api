var express = require('express'),
    poiApi = require('poi-api'),
    path = require('path'),
    exphbs  = require('express3-handlebars');

// Set the environment variables
var app = express();
app.set('port', process.env.PORT || 3000);

app.engine('handlebars', exphbs({defaultLayout: 'main'}));
app.set('view engine', 'handlebars');

// Error Logging
process.on('uncaughtException', function (err) {
  console.log('************************************************');
  console.log('*             UNCAUGHT EXCEPTION               *');
  console.log('************************************************');
  console.log('************************************************');
  console.log('************************************************');
  console.log('Caught exception: ' + err);
  console.log('Trace', err.stack);
  console.log('************************************************');
  console.log('************************************************');
  console.log('************************************************');
  console.log('************************************************');
});

// Forward the browse requests
app.get('/browse/*', function(req, res) {
  var suffix = '.html';
  console.log(req.url, req.url.indexOf('/node/'));
  if (req.url.indexOf('/node/') < 0) {
    suffix = '/full' + suffix;
  }
  res.redirect(req.url.replace('browse', 'api/0.6') + suffix);
});

// OSM API
app.use('/api', poiApi.routes());

// oauth (prob move this into poi-api soon!
app.use('/oauth', poiApi.oauth());

// iD Editor
app.use(express.static(path.join(__dirname, '/node_modules/iD')));

app.listen(app.get('port'));
console.log('Node.js server listening on port ' + app.get('port'));
