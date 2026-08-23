import fs from 'node:fs';
import dotenv from 'dotenv';
import { cert, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

dotenv.config();

const [identifier, role] = process.argv.slice(2);
const allowedRoles = new Set(['student', 'teacher', 'admin']);

if (!identifier || !allowedRoles.has(role)) {
  console.error('Usage: npm run set-role -- <firebase-uid-or-email> <student|teacher|admin>');
  process.exit(1);
}

const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
const serviceAccount = serviceAccountPath && fs.existsSync(serviceAccountPath)
  ? JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'))
  : {
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    };

if (!serviceAccount.projectId || !serviceAccount.clientEmail || !serviceAccount.privateKey) {
  console.error('Firebase Admin credentials are missing from .env.');
  process.exit(1);
}
initializeApp({
  credential: cert(serviceAccount),
  projectId: process.env.FIREBASE_PROJECT_ID,
});

const auth = getAuth();
const user = identifier.includes('@')
  ? await auth.getUserByEmail(identifier)
  : await auth.getUser(identifier);

await auth.setCustomUserClaims(user.uid, { role });
console.log(`Assigned role '${role}' to ${user.email ?? user.uid}.`);
console.log('The user must sign out and sign in again before the new role is used.');
