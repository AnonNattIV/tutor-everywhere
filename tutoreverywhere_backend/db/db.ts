import postgres from "postgres";
import "dotenv/config";

const sql = postgres({ssl: "require"});

export default sql;
