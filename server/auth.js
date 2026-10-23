const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET;

const JWT_ISSUER = 'game-tracker-app-server';

function generateToken(userId) {
  return jwt.sign({}, JWT_SECRET, {
    algorithm: 'HS256',      // header "alg": pinned per RFC 8725 / OWASP
    subject: String(userId), // claim "sub": the spec requires a string
    issuer: JWT_ISSUER,      // claim "iss": who made the token
    expiresIn: '7d',         // claim "exp": "iat" is added automatically from jsonwebtoken package
  });
}

function authenticateToken(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Authentication token required' });
  }
  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, JWT_SECRET, {
      algorithms: ['HS256'],
      issuer: JWT_ISSUER,
    });
    req.userId = Number(decoded.sub);
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

function checkSameUser(req, res, next) {
  if (Number(req.params.userId) !== req.userId) {
    return res.status(403).json({ error: 'Not allowed' });
  }
  next();
}

module.exports = { generateToken, authenticateToken, checkSameUser };