import { join } from 'path';
import fs from 'fs';
import { Pool } from 'pg';

import credentials from "../config/pg_credentials.json";

(async function createTables() {
  let postgresconn = credentials.connection.postgres;

  let database_config = {
    connectionString: postgresconn.composed[0],
    ssl: {
      ca: Buffer.from(postgresconn.certificate.certificate_base64, 'base64').toString()
    }
  };

  // Create a pool.
  let pool = new Pool(database_config);
  const client = await pool.connect();

  let bank = fs.readFileSync(join(__dirname,'../config/bank.sql')).toString();
  await client.query(bank);

  process.exit(0)
}())
.catch(error => console.error(error));