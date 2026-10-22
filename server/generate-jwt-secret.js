const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const envPath = path.join(__dirname, '.env');
const envContent = fs.existsSync(envPath) ? fs.readFileSync(envPath, 'utf8') : '';

// A line starting with JWT_SECRET= followed by at least one non-space character
if (/^\s*JWT_SECRET=\S/m.test(envContent)) {
  console.log('JWT_SECRET already set in .env, leaving it alone');
} else {
  const secret = crypto.randomBytes(32).toString('hex'); // 256 bits for HS256
  fs.appendFileSync(envPath, `\nJWT_SECRET=${secret}\n`);
  console.log('JWT_SECRET added to .env');
}