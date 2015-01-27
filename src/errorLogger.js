var winston = require('winston');
module.exports = new(winston.Logger)({
  exitOnError: false,
  transports: [
    new(winston.transports.File)({
      name: 'info-file',
      filename: 'filelog-info.log',
      level: 'info'
    }),
    new(winston.transports.File)({
      name: 'error-file',
      filename: 'filelog-error.log',
      level: 'error'
    }),
    new(winston.transports.Console)({
      name: 'error-console',
      level: 'error'
    }),
    new(winston.transports.File)({
      name: 'debug-file',
      filename: 'filelog-debug.log',
      level: 'debug'
    }),
    new(winston.transports.Console)({
      name: 'debug-console',
      level: 'debug'
    })
  ]
});
