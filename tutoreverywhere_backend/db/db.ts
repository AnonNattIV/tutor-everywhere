import postgres from "postgres";
import "dotenv/config";

const dbPort = process.env.PGPORT || process.env.DB_PORT;
const sslMode = process.env.PGSSL || process.env.DB_SSL;

const sql = postgres({
  host: process.env.PGHOST || process.env.DB_HOST,
  port: dbPort ? Number(dbPort) : undefined,
  database: process.env.PGDATABASE || process.env.DB_DATABASE,
  username: process.env.PGUSER || process.env.DB_USERNAME,
  password: process.env.PGPASSWORD || process.env.DB_PASSWORD,
  ssl: sslMode === "disable" || sslMode === "false" ? false : "require",
});

export default sql;
