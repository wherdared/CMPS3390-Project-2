const express = require('express');
const pool = require('./db/connection');

const app = express();
app.use(express.json());

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

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});