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

module.exports = { generateToken };