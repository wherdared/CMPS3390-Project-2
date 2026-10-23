const jwt = require('jsonwebtoken');
const crypto = require('crypto');

const JWT_SECRET = process.env.JWT_SECRET;

const JWT_ISSUER = 'game-tracker-app-server';

// IDs ("jti") of logged-out tokens. In memory: cleared if the server restarts.
const revokedTokenIds = new Set();

function generateToken(userId) {
  return jwt.sign({}, JWT_SECRET, {
    algorithm: 'HS256',      // header "alg": pinned per RFC 8725 / OWASP
    subject: String(userId), // claim "sub": the spec requires a string
    issuer: JWT_ISSUER,      // claim "iss": who made the token
    expiresIn: '7d',         // claim "exp": "iat" is added automatically from jsonwebtoken package
    jwtid: crypto.randomUUID(), // claim "jti": unique id, so this one token can be revoked
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
    if (revokedTokenIds.has(decoded.jti)) {
      return res.status(401).json({ error: 'Invalid or expired token' });
    }
    req.userId = Number(decoded.sub);
    req.tokenId = decoded.jti;
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

// Logout: this token's id goes on the denylist, so the token stops working
function revokeToken(req, res) {
  revokedTokenIds.add(req.tokenId);
  res.json({ loggedOut: true });
}

module.exports = { generateToken, authenticateToken, checkSameUser, revokeToken };