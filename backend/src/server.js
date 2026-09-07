import express from 'express';
import cors from 'cors';
import crypto from 'node:crypto';
import dotenv from 'dotenv';
import fs from 'node:fs';
import path from 'node:path';
import { initializeApp, getApps } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { cert } from 'firebase-admin/app';
import nodemailer from 'nodemailer';

dotenv.config();

const app = express();
const port = Number(process.env.PORT || 4000);
const otpStore = new Map();

// Configure CORS to allow requests from Flutter web
app.use(cors({
  origin: ['http://localhost:8080', 'http://127.0.0.1:8080', 'http://localhost:3000'],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

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

    return res.json({
      success: true,
      user: {
        uid: decodedToken.uid,
        email: decodedToken.email ?? null,
        name: decodedToken.name ?? null,
        picture: decodedToken.picture ?? null,
        provider: decodedToken.firebase?.sign_in_provider ?? 'firebase',
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

function hashOtp(otp) {
  return crypto.createHash('sha256').update(otp).digest('hex');
}

function getMailTransport() {
  const { SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASSWORD } = process.env;
  if (!SMTP_HOST || !SMTP_PORT || !SMTP_USER || !SMTP_PASSWORD) {
    throw new Error('SMTP configuration is missing.');
  }
  return nodemailer.createTransport({
    host: SMTP_HOST,
    port: Number(SMTP_PORT),
    secure: process.env.SMTP_SECURE === 'true',
    auth: { user: SMTP_USER, pass: SMTP_PASSWORD },
  });
}

app.post('/api/auth/password-reset/request', async (req, res) => {
  try {
    const email = String(req.body?.email ?? '').trim().toLowerCase();
    if (!email) {
      return res.status(400).json({ success: false, message: 'Email is required.' });
    }

    const user = await getAuth().getUserByEmail(email);
    const otp = String(crypto.randomInt(100000, 1000000));
    otpStore.set(email, {
      hash: hashOtp(otp),
      expiresAt: Date.now() + 10 * 60 * 1000,
      attempts: 0,
      uid: user.uid,
    });

    await getMailTransport().sendMail({
      from: process.env.SMTP_FROM || process.env.SMTP_USER,
      to: email,
      subject: 'PeerLearnHub password reset code',
      text: `Your PeerLearnHub password reset code is ${otp}. It expires in 10 minutes.`,
      html: `<p>Your PeerLearnHub password reset code is:</p><h2>${otp}</h2><p>This code expires in 10 minutes.</p>`,
    });

    return res.json({ success: true, message: 'Verification code sent.' });
  } catch (error) {
    if (error?.code === 'auth/user-not-found') {
      return res.status(404).json({ success: false, message: 'No account exists for this email.' });
    }
    console.error('Password reset request failed:', error);
    return res.status(503).json({ success: false, message: 'Unable to send the verification code.' });
  }
});

app.post('/api/auth/password-reset/verify', async (req, res) => {
  try {
    const email = String(req.body?.email ?? '').trim().toLowerCase();
    const otp = String(req.body?.otp ?? '').trim();
    const newPassword = String(req.body?.newPassword ?? '');
    const pending = otpStore.get(email);

    if (!pending || pending.expiresAt < Date.now()) {
      otpStore.delete(email);
      return res.status(400).json({ success: false, message: 'The code is invalid or expired.' });
    }
    if (pending.attempts >= 5) {
      otpStore.delete(email);
      return res.status(429).json({ success: false, message: 'Too many attempts. Request a new code.' });
    }
    pending.attempts += 1;
    if (!/^\d{6}$/.test(otp) || hashOtp(otp) !== pending.hash) {
      return res.status(400).json({ success: false, message: 'The verification code is incorrect.' });
    }
    if (newPassword.length < 6) {
      return res.status(400).json({ success: false, message: 'Password must be at least 6 characters.' });
    }

    await getAuth().updateUser(pending.uid, { password: newPassword });
    otpStore.delete(email);
    return res.json({ success: true, message: 'Password updated successfully.' });
  } catch (error) {
    console.error('Password reset verification failed:', error);
    return res.status(500).json({ success: false, message: 'Unable to reset the password.' });
  }
});

// Assignment submission endpoint
app.post('/api/assignments/submit', async (req, res) => {
  try {
    const { idToken, courseId, description, githubUrl } = req.body;
    
    if (!idToken) {
      return res.status(401).json({ success: false, message: 'Authentication required.' });
    }

    // Verify Firebase token
    const decodedToken = await getAuth().verifyIdToken(idToken);
    const userId = decodedToken.uid;

    if (!courseId || !description || !githubUrl) {
      return res.status(400).json({ success: false, message: 'Missing required fields.' });
    }

    // Validate GitHub URL
    try {
      const githubUrlObj = new URL(githubUrl.trim());
      if (!githubUrlObj.hostname.includes('github.com')) {
        return res.status(400).json({ success: false, message: 'Invalid GitHub URL.' });
      }
    } catch {
      return res.status(400).json({ success: false, message: 'Invalid GitHub URL format.' });
    }

    // Save assignment data to Firestore (without file)
    const db = getFirestore();
    await db.collection('users').doc(userId).collection('assignments').doc(courseId).set({
      courseId,
      description: description.trim(),
      githubUrl: githubUrl.trim(),
      status: 'submitted',
      submittedAt: new Date(),
      updatedAt: new Date(),
    }, { merge: true });

    return res.json({ 
      success: true, 
      message: 'Assignment submitted successfully'
    });
  } catch (error) {
    console.error('Assignment submission failed:', error);
    return res.status(500).json({ 
      success: false, 
      message: error.message || 'Assignment submission failed.' 
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
