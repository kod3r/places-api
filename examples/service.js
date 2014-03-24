// https://github.com/coreybutler/node-windows
//
// npm install -g node-windows
// npm link node-windows
// node service.js


var Service = require('node-windows').Service;

// Create a new service object
var svc = new Service({
  name:'Places of Interest Node.js App',
  description: 'the poi-api for the node.js app that runs the Places of Interest project.',
  script: 'C:\\poi-website\\app.js'
});

// Listen for the "install" event, which indicates the
// process is available as a service.
svc.on('install',function(){
  svc.start();
});

svc.install();
