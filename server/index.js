const express = require('express');
const pool = require('./db/connection');
const crypto = require('crypto');
const argon2 = require('argon2');

const app = express();
app.use(express.json());

app.use((req, res, next) => {
  console.log(req.method, req.url);
  next();
});

const VALID_STATUSES = ['want to play', 'playing', 'finished'];

app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ok' });
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ error: 'Database unavailable' });
  }
});

app.get('/users/:userId/lists', async (req, res) => {
  const userId = Number(req.params.userId);

  if (!Number.isInteger(userId) || userId <= 0) {
    return res.status(400).json({ error: 'Invalid user id' });
  }

  try {
    const result = await pool.query(
      'SELECT id, name FROM lists WHERE user_id = $1 ORDER BY name',
      [userId]
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ error: 'Could not load lists' });
  }
});

app.post('/users/:userId/lists/:listId/games', async (req, res) => {
  const userId = Number(req.params.userId);
  const listId = Number(req.params.listId);
  const rawgId = Number(req.body.rawg_id);
  const status = req.body.status === undefined ? 'want to play' : req.body.status;

  if (!Number.isInteger(userId) || userId <= 0) {
    return res.status(400).json({ error: 'Invalid user id' });
  }
  if (!Number.isInteger(listId) || listId <= 0) {
    return res.status(400).json({ error: 'Invalid list id' });
  }
  if (!Number.isInteger(rawgId) || rawgId <= 0 || rawgId > 2147483647) {
    return res.status(400).json({ error: 'Invalid game id' });
  }
  if (!VALID_STATUSES.includes(status)) {
    return res.status(400).json({ error: 'Invalid status' });
  }

  try {
    const list = await pool.query(
      'SELECT id FROM lists WHERE id = $1 AND user_id = $2',
      [listId, userId]
    );
    if (list.rows.length === 0) {
      return res.status(404).json({ error: 'List not found' });
    }

    const result = await pool.query(
      `INSERT INTO list_entries (list_id, rawg_id, status)
       VALUES ($1, $2, $3)
       RETURNING id, list_id, rawg_id, status`,
      [listId, rawgId, status]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ error: 'Game is already in this list' });
    }
    console.error(err.message);
    res.status(500).json({ error: 'Could not add game to list' });
  }
});

const USERNAME_RegEX = /^[a-z0-9_]{3,18}$/;
let dummyHash;
async function createDummyHash() {
  dummyHash = await argon2.hash(crypto.randomBytes(32).toString('hex'));
}
createDummyHash();

function readCreds(req) {
  const body = req.body || {};

  const username = String(body.username || '').trim().toLowerCase(); // toLowerCase because without it, Snowy and snowy would be two different users
  const password = String(body.password || '');

  return { username, password };
}

app.post('/signup', async (req, res) => {
  const { username, password } = readCreds(req);
  
  // Input validation
  if (!USERNAME_RegEX.test(username)) {
    return res.status(400).json({ error: 'Username must be 3-18 lowercase letters, numbers, or _' });
  }
  if (password.length < 8 || password.length > 128) {
    return res.status(400).json({ error: 'Password must be 8-128 characters' });
  }

  // Argon2id hashing algorithm salts the password and stores it inside the hash string
  const passwordHash = await argon2.hash(password);

  // node-postgres docs recommend pool.connect() for a transaction that saves multiple things
  // either saves all items or nothing at all so a user isn't left without all items
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const userInsertResult = await client.query(
      'INSERT INTO users (username, password_hash) VALUES ($1, $2) RETURNING id, username',
      [username, passwordHash]
    );
    const user = userInsertResult.rows[0];

    await client.query(
      'INSERT INTO lists (user_id, name) VALUES ($1, $2)',
      [user.id, 'My Games']
    );

    await client.query('COMMIT');
    res.status(201).json(user); // client then sends the user to Log In
  } catch (err) {
    await client.query('ROLLBACK');

    if (err.code === '23505') {
      return res.status(409).json({ error: 'Username is taken' });
    }

    throw err;
  } finally {
    client.release();
  }
});

app.post('/login', async (req, res) => {
  const { username, password } = readCreds(req);

  const result = await pool.query(
    'SELECT id, username, password_hash FROM users WHERE username = $1',
    [username]
  );
  const user = result.rows[0]; // undefined if no user has that username

  // Always run verify, even for unknown usernames, so response time doesn't reveal which usernames exist
  // .catch(() => false) treats a broken or non-Argon2 hash as a wrong password instead of crashing
  const hashToCheck = user ? user.password_hash : dummyHash;
  const passwordMatches = await argon2.verify(hashToCheck, password).catch(() => false);

  if (!user || !passwordMatches) {
    return res.status(401).json({ error: 'Invalid username or password' });
  }

  // TODO: create the signed JWT here and send it along
  res.json({ id: user.id, username: user.username });
});

// error handler
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'Something went wrong' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});