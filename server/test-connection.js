require('dotenv').config();
const { Client } = require('pg');

async function main() {
  const client = new Client({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false },
  });

  await client.connect();

  const time = await client.query('SELECT NOW()');
  console.log('Connected! Server time:', time.rows[0].now);

  const tables = await client.query(
    "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'"
  );
  console.log('Tables found:', tables.rows.map((row) => row.table_name));

  await client.end();
}

main().catch((err) => {
  console.error('Connection failed:', err.message);
  process.exit(1);
});