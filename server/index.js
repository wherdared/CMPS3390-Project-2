const express = require('express');
const pool = require('./db/connection');

const app = express();
app.use(express.json());

const VALID_STATUSES = ['want to play', 'playing', 'finished'];

// Health check: confirms that the server can reach the database
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ok' });
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ error: 'Database unavailable' });
  }
});

// Get all of a user's lists, each with its id, name, and number of games
app.get('/users/:userId/lists', async (req, res) => {
  const userId = Number(req.params.userId);

  if (!Number.isInteger(userId) || userId <= 0) {
    return res.status(400).json({ error: 'Invalid user id' });
  }

  try {
    const result = await pool.query(
      `SELECT lists.id, lists.name, COUNT(list_entries.id)::int AS game_count 
      FROM lists
      LEFT JOIN list_entries ON list_entries.list_id = lists.id
      WHERE lists.user_id = $1
      GROUP BY lists.id, lists.name
      ORDER BY lists.name`,
      [userId]
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ error: 'Could not load lists' });
  }
});

// Creates a new list for a user from the name sent in the request
app.post('/users/:userId/lists', async (req, res) => {
  const userId = Number(req.params.userId);
  const name = typeof req.body.name === 'string' ? req.body.name.trim() : '';

  if (!Number.isInteger(userId) || userId <= 0) {
    return res.status(400).json({ error: 'Invalid user id' });
  }
  if (name.length === 0) {
    return res.status(400).json({ error: 'List name is required'});
  }
  if (name.length === 0) {
    return res.status(400).json({ error: 'List name must be 50 characters or less'});
  }

  try {
    const result =  await pool.query(
      'INSERT INTO lists (user_id, name) VALUES ($1, $2) RETURNING id, name',
      [userId, name]
    );
    res.status(201).json({ ...result.rows[0], game_count: 0 });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ error: 'You already have a list with that name'});
    }
    if (err.code === '23503') {
      return res.status(404).json({ error: 'User not found' });
    }
    console.error(err.message);
    res.status(500).json({ error: 'Could not create list '});
  }
});


app.patch('/users/:userId/lists/:listId', async (req, res) => {
  const userId = Number(req.params.userId);
  const listId = Number(req.params.listId);
  const name = typeof req.body.name === 'string' ? req.body.name.trim() : '';

  if (!Number.isInteger(userId) || userId <= 0) {
    return res.status(400).json({ error: 'Invalid user id' });
  }
  if (!Number.isInteger(listId) || listId <= 0) {
    return res.status(400).json({ error: 'Invalid list id' });
  }
  if (name.length === 0) {
    return res.status(400).json({ error: 'List name is required' });
  }
  if (name.length > 50) {
    return res.status(400).json({ error: 'List name must be 50 characters or less'});
  }

  try {
    const result = await pool.query(
      'Update lists SET name = $1 WHERE id = $2 AND user_id = $3 RETURNING id, name',
      [name, listId, userId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'List not found '});
    }
    res.json(result.rows[0]);
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ error: "You already have a list with that name"})
    }
    console.error(err.message);
    res.status(500).json({ error: 'Could not rename list' });
  }
});

// Deletes one of the users's lists (its games are deleted with it)
app.delete('/users/:userId/lists/:listId', async (req, res) => {
  const userId = Number(req.params.userId);
  const listId = Number(req.params.listId);

  if (!Number.isInteger(userId) || userId <= 0) {
    return res.status(400).json({ error: 'Invalid user id' });
  }
  if (!Number.isInteger(listId) || listId <= 0) {
    return res.status(400).json({ error: 'Invalid list id' });
  }

  try {
    const result = await pool.query(
      'DELETE FROM lists WHERE id = $1 AND user_id = $2 RETURNING id',
      [listId, userId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'List not found' });
    }
    res.json({ deleted: true });
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ error: 'Couldn not delete list' });
  }
});

// Gets the games in one of the user's lists (the id, RAWG id, and status of each)
app.get('/users/:userId/lists/:listId/games', async (req, res) => {
  const userId = Number(req.params.userId);
  const listId = Number(req.params.listId);

  if (!Number.isInteger(userId) || userId <= 0) {
    return res.status(400).json({ error: 'Invalid user id' });
  }
  if (!Number.isInteger(listId) || listId <= 0) {
    return res.status(400).json({ error: 'Invalid list id' });
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
      'SELECT id, rawg_id, status FROM list_entries WHERE list_id = $1 ORDER BY id',
      [listId]
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ error: 'Could not load games' });
  }
});

// Removes a game (by its RAWG id) from one of the user's lists
app.delete('/users/:userId/lists/:listId/games/:rawgId', async (req, res) => {
  const userId = Number(req.params.userId);
  const listId = Number(req.params.listId);
  const rawgId = Number(req.params.rawgId);

  if (!Number.isInteger(userId) || userId <= 0) {
    return res.status(400).json({ error: 'Invalid user id' });
  }
  if (!Number.isInteger(listId) || listId <= 0) {
    return res.status(400).json({ error: 'Invalid list id' });
  }
  if (!Number.isInteger(rawgId) || rawgId <= 0 || rawgId > 2147483647) {
    return res.status(400).json({ error: 'Invalid game id' });
  }

  try {
    const result = await pool.query(
      `DELETE FROM list_entries
       USING lists
       WHERE list_entries.list_id = lists.id
         AND lists.id = $1
         AND lists.user_id = $2
         AND list_entries.rawg_id = $3
       RETURNING list_entries.id`,
      [listId, userId, rawgId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Game not found in this list' });
    }
    res.json({ deleted: true });
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ error: 'Could not remove game' });
  }
});

// Adds a game (by its RAWG id) to one of the user's lists
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

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});