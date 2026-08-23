import fs from 'node:fs';
import dotenv from 'dotenv';
import { cert, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

dotenv.config();

const [identifier] = process.argv.slice(2);

if (!identifier) {
  console.error('Usage: npm run reset-role -- <firebase-uid-or-email>');
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

await auth.setCustomUserClaims(user.uid, {});
await getFirestore().collection('users').doc(user.uid).set(
  { role: null },
  { merge: true },
);
console.log(`Reset the role for ${user.email ?? user.uid}.`);
console.log('Sign out and sign in again to choose a new role.');
