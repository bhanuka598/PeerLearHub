import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import fs from 'node:fs';
import path from 'node:path';
import { initializeApp, getApps } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { cert } from 'firebase-admin/app';

dotenv.config();

const app = express();
const port = Number(process.env.PORT || 4000);

app.use(cors({ origin: true, credentials: true }));
app.use(express.json({ limit: '2mb' }));

function initializeFirebaseAdmin() {
  if (getApps().length > 0) {
    return;
  }

  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  if (serviceAccountPath) {
    const resolvedPath = path.isAbsolute(serviceAccountPath)
      ? serviceAccountPath
      : path.resolve(process.cwd(), serviceAccountPath);

    if (fs.existsSync(resolvedPath)) {
      const serviceAccount = JSON.parse(fs.readFileSync(resolvedPath, 'utf8'));
      initializeApp({
        credential: cert(serviceAccount),
        projectId: process.env.FIREBASE_PROJECT_ID,
      });
      return;
    }
  }

  const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const projectId = process.env.FIREBASE_PROJECT_ID;

  if (privateKey && clientEmail && projectId) {
    initializeApp({
      credential: cert({
        projectId,
        privateKey,
        clientEmail,
      }),
      projectId,
    });
    return;
  }

  throw new Error(
    'Firebase Admin credentials are missing. Set FIREBASE_SERVICE_ACCOUNT_PATH '
      + 'or FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, and FIREBASE_PRIVATE_KEY.',
  );
}

initializeFirebaseAdmin();

app.get('/api/health', (_req, res) => {
  res.json({
    ok: true,
    service: 'peer-learn-hub-backend',
    timestamp: new Date().toISOString(),
  });
});

app.post('/api/auth/verify-token', async (req, res) => {
  try {
    const { idToken } = req.body ?? {};

    if (!idToken || typeof idToken !== 'string') {
      return res.status(400).json({
        success: false,
        message: 'Missing Firebase ID token.',
      });
    }

    const decodedToken = await getAuth().verifyIdToken(idToken);
    const userSnapshot = await getFirestore()
      .collection('users')
      .doc(decodedToken.uid)
      .get();
    const savedRole = userSnapshot.data()?.role;
    const role = ['student', 'teacher', 'admin'].includes(savedRole)
      ? savedRole
      : ['student', 'teacher', 'admin'].includes(decodedToken.role)
        ? decodedToken.role
        : null;

    return res.json({
      success: true,
      user: {
        uid: decodedToken.uid,
        email: decodedToken.email ?? null,
        name: decodedToken.name ?? null,
        picture: decodedToken.picture ?? null,
        provider: decodedToken.firebase?.sign_in_provider ?? 'firebase',
        role,
      },
    });
  } catch (error) {
    if (
      error?.code === 'auth/argument-error' ||
      error?.code === 'auth/id-token-expired' ||
      error?.code === 'auth/invalid-id-token'
    ) {
      console.warn(`Firebase token rejected (${error.code}).`);
    } else {
      console.error('Firebase token verification failed:', error);
    }
    return res.status(401).json({
      success: false,
      message: 'Invalid or expired Firebase token.',
    });
  }
});

app.post('/api/auth/role', async (req, res) => {
  try {
    const authorization = req.headers.authorization ?? '';
    const idToken = authorization.startsWith('Bearer ')
      ? authorization.substring('Bearer '.length)
      : '';
    const { role } = req.body ?? {};

    if (!idToken || !['student', 'teacher', 'admin'].includes(role)) {
      return res.status(400).json({
        success: false,
        message: 'A valid Firebase token and role are required.',
      });
    }

    const decodedToken = await getAuth().verifyIdToken(idToken);
    const userReference = getFirestore()
      .collection('users')
      .doc(decodedToken.uid);
    const result = await getFirestore().runTransaction(async (transaction) => {
      const savedUser = await transaction.get(userReference);
      const existingRole = savedUser.data()?.role;
      if (savedUser.exists && existingRole) {
        return { role: existingRole, created: false };
      }

      transaction.set(
        userReference,
        {
          uid: decodedToken.uid,
          email: decodedToken.email ?? null,
          displayName: decodedToken.name ?? null,
          role,
          createdAt: new Date().toISOString(),
        },
        { merge: true },
      );
      return { role, created: true };
    });

    return res.status(result.created ? 201 : 200).json({
      success: true,
      role: result.role,
      locked: true,
    });
  } catch (error) {
    console.error('Role persistence failed:', error);
    return res.status(401).json({
      success: false,
      message: 'Unable to save the account role.',
    });
  }
});

app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Route not found: ${req.method} ${req.originalUrl}`,
  });
});

app.listen(port, () => {
  console.log(`PeerLearnHub backend listening on http://localhost:${port}`);
});
