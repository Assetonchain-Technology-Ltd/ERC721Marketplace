const { createLogger, format, transports } = require('winston');
require('winston-daily-rotate-file');
const fs = require('fs');
const path = require('path');

const env = process.env.NODE_ENV || 'development';
const logDir = 'log';

if (!fs.existsSync(logDir)) {
  fs.mkdirSync(logDir);
}

const dailyRotatedebugFileTransport = new transports.DailyRotateFile({
  filename: `${logDir}/%DATE%-debug.log`,
  datePattern: 'YYYY-MM-DD',
  level:'silly'
});


const logger = createLogger({
  // change level if in dev environment versus production
  //level: env === 'development' ? 'verbose' : 'info',
  level: 'debug',
  format: format.combine(
    format.colorize(),
	format.prettyPrint(),
    format.label({ label: path.basename(process.mainModule.filename) }),
    format.timestamp({
      format: 'YYYY-MM-DD HH:mm:ss'
    }),
    format.printf(info => `${info.timestamp} ${info.level} [${info.label}]: ${info.message}`)
  ),
  transports: [
    new transports.Console({level:'debug'}),
	dailyRotatedebugFileTransport
  ]
});

logger.stream = {
  write: function(message, encoding) {
    logger.silly(message);
  },
};

module.exports = logger;
