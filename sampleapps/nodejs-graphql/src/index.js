import express from "express";
import compression from "compression";
import cookieParser from "cookie-parser";
import cookieSession from "cookie-session";
import morgan from "morgan";
import { hostname } from "os";
import chalk from "chalk";
import { join } from 'path';
import { Pool } from 'pg';
import ibmcossdk from 'ibm-cos-sdk';
import fs from 'fs';
import { v5 as uuidv5 } from 'uuid';
import { updateItemsInBucket } from './lib/cos' ;

import config from "../config/config.json";

const port = 80;
const APP_BUILD_PATH = "build";
const { NODE_ENV = "development" } = process.env;
const isLocal = NODE_ENV !== "production";
const cookieSecret = config.cookie;
const expiresIn = 1 * 1 * 15 * 60; // days * hours * minutes * seconds  = 15 minutes
const cookiesPrefix = require("../package.json").prefixes
  .cookiesPrefix;

const custom =
  ':remote-addr - :remote-user [:date[clf]] ":method :url HTTP/:http-version" :status :res[content-length] ":referrer" ":user-agent" :response-time ms :pid :local-address';

const system = require("./utils/logger").systemLog(APP_BUILD_PATH);
const access = require("./utils/logger").accessLog(APP_BUILD_PATH);
const app = express();

app.use(compression());

morgan.token("pid", req => process.pid);
morgan.token("local-address", req => req.socket.address().port);

app.use(morgan(custom, { skip: (req, res) => res.statusCode < 400 }));
app.use(morgan(custom, { stream: access }));
app.use(cookieParser());
app.use(
  cookieSession({
    name: `${cookiesPrefix}session`,
    secret: cookieSecret,
    maxAge: expiresIn * 1000, // expiresIn * ms
    httpOnly: true, // default is true
    secure: true, // default is true
    signed: true // default is true
  })
);

// Add a 0.5 second delay to all responses (used for testing)
app.use((req, res, next) => setTimeout(next, 500));

(async function connectDBCOSAddRoutes() {
  if (config.cloud_object_storage) {
    const cos_credentials = require("../config/cos_credentials.json");
    const { getEndpoints } = require('./lib/cos');
    const pg_credentials = require("../config/pg_credentials.json");

    let cos;
    const { cloud_object_storage: { bucketName, endpoint_type, region, type, location, update } } = config;
    const { guid } = cos_credentials[0];

    let endpoints = await getEndpoints(`${cos_credentials[0].credentials.endpoints}`, type);
    if (endpoints["service-endpoints"]) {
      let endpoint = endpoints["service-endpoints"][endpoint_type][region][type][location]

      let cos_config = {
        endpoint: endpoint,
        apiKeyId: cos_credentials[0].credentials.apikey,
        ibmAuthEndpoint: 'https://iam.cloud.ibm.com/identity/token',
        serviceInstanceId: cos_credentials[0].credentials.resource_instance_id
      };
      
      cos = new ibmcossdk.S3(cos_config);
    }

    // let bucket = `${bucketName}-${uuidv5(bucketName, guid)}`;

    if (update === "true") {
      const updateInterval = 5 * 60 * 1000;
      setInterval(() => updateItemsInBucket(cos, bucketName), updateInterval);
    }

    // Connection String is failing starting in pg 8.5.x: https://github.com/brianc/node-postgres/issues/2009#issuecomment-753211352
    // let database_config = {
    //   connectionString: pg_credentials[0].credentials.connection.postgres.composed[0],
    //   ssl: {
    //     ca: Buffer.from(pg_credentials[0].credentials.connection.postgres.certificate.certificate_base64, 'base64').toString()
    //   }
    // };

    let user = pg_credentials[0].credentials.connection ? pg_credentials[0].credentials.connection.postgres.authentication.username : pg_credentials[0].credentials["connection.postgres.authentication.username"];
    let host = pg_credentials[0].credentials.connection ? pg_credentials[0].credentials.connection.postgres.hosts[0].hostname : pg_credentials[0].credentials["connection.postgres.hosts.0.hostname"];
    let database = pg_credentials[0].credentials.connection ? pg_credentials[0].credentials.connection.postgres.database : pg_credentials[0].credentials["connection.postgres.database"];

    let database_config = {
      user: user,
      host: host,
      database: database,
      password: pg_credentials[0].credentials.connection ? pg_credentials[0].credentials.connection.postgres.authentication.password : pg_credentials[0].credentials["connection.postgres.authentication.password"],
      port: pg_credentials[0].credentials.connection ? pg_credentials[0].credentials.connection.postgres.hosts[0].port : pg_credentials[0].credentials["connection.postgres.hosts.0.port"],
      ssl: {
        rejectUnauthorized: true,
        ca: Buffer.from(pg_credentials[0].credentials.connection ? pg_credentials[0].credentials.connection.postgres.certificate.certificate_base64 : pg_credentials[0].credentials["connection.postgres.certificate.certificate_base64"], 'base64').toString(),
      },
    };

    // Create a pool.
    let pool = new Pool(database_config);

    pool.on('error', (err) => {
      console.error(`${chalk.red(`Unexpected error on idle client`)}`, err.stack)
    });

    require("./bank/routes")(app, pool, cos, bucketName, host); //`${bucketName}-${uuidv5(bucketName, guid)}`
  }

  if (config.cockroach) {
    const { cockroach: { user, host, database, port } } = config;
    let database_config = {
      user: user,
      host: host,
      database: database,
      port: port,
      connectionTimeoutMillis: 2000,
      ssl: {
        ca: fs.readFileSync(join(__dirname, '../certs/ca.crt')).toString(),
        key: fs.readFileSync(join(__dirname,'../certs/client.maxroach.key')).toString(),
        cert: fs.readFileSync(join(__dirname,'../certs/client.maxroach.crt')).toString()
      }
    };

    // Create a pool.
    let pool = new Pool(database_config);
    
    pool.on('error', (err) => {
      console.error(`${chalk.red(`Unexpected error on idle client`)}`, err.stack)
    });

    require("./bank/routes")(app, pool);
  }

  app.use("/health", function (req, res, next) {
    res.json({status: 'UP'});
  });

  // Following middleware and routes need to come in order before app.listen
  app.get('*', (req,res) => {
      res.sendFile(join(__dirname,'./public/index.html'));
  });

  app.use((req, res, next) => {
      let err = new Error('The address or route you entered does not exist on this server.');
      err.status = 404;
      err.code = 'ROUTE_NOT_FOUND'
      next(err);
  });

  app.use((err, req, res, next) => {
      res.status(err.status || 500).send({
          data: {},
          errors: [{
              message: err.message,
              code: err.code,
              timestamp: ""
          }]
      });
  });

  app.listen(port, () => {
    system.info(`Server process ${process.pid} is listening on ${hostname}:${port}`);
    console.log(
      `Use the following uri to access the app using your server or load balancer hostname: ${chalk.green(`/api/bank`)}`
    );
  });

}())
  .catch(error => console.error(error));