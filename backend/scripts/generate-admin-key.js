#!/usr/bin/env node
/**
 * Generate a secure admin key for moderator registration
 * Usage: node scripts/generate-admin-key.js
 * 
 * Output formats:
 * - Default: Full display with instructions
 * --quiet: Output only the key (for scripts)
 */

import crypto from 'crypto';

function generateSecureAdminKey() {
  const length = 32;
  const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*';
  let result = '';
  const values = new Uint32Array(length);
  crypto.randomFillSync(values);
  for (let i = 0; i < length; i++) {
    result += charset[values[i] % charset.length];
  }
  return result;
}

const adminKey = generateSecureAdminKey();
const args = process.argv.slice(2);

// Check for --quiet flag
if (args.includes('--quiet')) {
  console.log(adminKey);
} else {
  console.log('==========================================');
  console.log('  Admin Key Generated Successfully');
  console.log('==========================================');
  console.log('');
  console.log('🔑 Your Admin Key:');
  console.log('   ' + adminKey);
  console.log('');
  console.log('📝 Add this to your .env file:');
  console.log('   MODERATOR_ADMIN_KEY=' + adminKey);
  console.log('');
  console.log('⚠️  Security Notes:');
  console.log('   - Store this key securely');
  console.log('   - Never commit it to version control');
  console.log('   - Rotate it periodically in production');
  console.log('   - Share only with trusted administrators');
  console.log('==========================================');
}
