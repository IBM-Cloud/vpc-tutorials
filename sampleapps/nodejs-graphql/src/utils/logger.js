import fs from "fs";
import path from "path";
import winston from "winston";
require("winston-daily-rotate-file");

import FileStreamRotator from "./FileStreamRotator";

const systemLog = build => {
  const appRoot = fs.realpathSync(process.cwd());
  const resolveApp = relativePath => path.resolve(appRoot, relativePath);
  const appBuild = resolveApp(build);
  let logDirectory = appBuild + "/logs";
  if (!fs.existsSync(logDirectory)) {
    fs.mkdirSync(logDirectory);
  }

  let systemLog = new winston.createLogger({
    transports: [
      new winston.transports.DailyRotateFile({
        name: "info-log",
        filename: logDirectory + "/system-%DATE%.log",
        datePattern: "YYYYMMDD",
        localTime: true,
        level: "info"
      }),
      new winston.transports.DailyRotateFile({
        name: "error-log",
        filename: logDirectory + "/error-%DATE%.log",
        datePattern: "YYYYMMDD",
        localTime: true,
        level: "error",
        handleExceptions: true
      })
    ],
    exitOnError: false
  });

  return systemLog;
};

const accessLog = build => {
  const appRoot = fs.realpathSync(process.cwd());
  const resolveApp = relativePath => path.resolve(appRoot, relativePath);
  const appBuild = resolveApp(build);
  let logDirectory = appBuild + "/logs";
  if (!fs.existsSync(logDirectory)) {
    fs.mkdirSync(logDirectory);
  }

  let accessLog = FileStreamRotator.getStream({
    date_format: "YYYYMMDD",
    filename: logDirectory + "/access-%DATE%.log",
    frequency: "daily",
    verbose: false
  });

  return accessLog;
};

export { systemLog, accessLog };
