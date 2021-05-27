import { join } from 'path';
import fs from 'fs';
import { Pool } from 'pg';
import chalk from "chalk";

import pg_credentials from "../config/pg_credentials.json";

const credentials = pg_credentials[0].credentials;

(async function createTables() {
    // Connection String is failing starting in pg 8.5.x: https://github.com/brianc/node-postgres/issues/2009#issuecomment-753211352
    // let database_config = {
    //   connectionString: pg_credentials[0].credentials.connection.postgres.composed[0],
    //   ssl: {
    //     ca: Buffer.from(pg_credentials[0].credentials.connection.postgres.certificate.certificate_base64, 'base64').toString()
    //   }
    // };

  let database_config = {
    user: pg_credentials[0].credentials["connection.postgres.authentication.username"],
    host: pg_credentials[0].credentials["connection.postgres.hosts.0.hostname"],
    database: pg_credentials[0].credentials["connection.postgres.database"],
    password: pg_credentials[0].credentials["connection.postgres.authentication.password"],
    port: pg_credentials[0].credentials["connection.postgres.hosts.0.port"],
    ssl: {
      rejectUnauthorized: true,
      ca: Buffer.from(pg_credentials[0].credentials["connection.postgres.certificate.certificate_base64"], 'base64').toString(),
    },
  };

  // Create a pool.
  let pool = new Pool(database_config);
  const client = await pool.connect();

  let bank = fs.readFileSync(join(__dirname,'../config/bank.sql')).toString();
  await client.query(bank);

  console.log(
    `${chalk.green(`Table(s) created!`)}`
  );
  process.exit(0)
}())
.catch(error => console.error(error));