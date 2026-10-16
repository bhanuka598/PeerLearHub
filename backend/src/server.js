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
  origin: true,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use(express.json({ limit: '2mb' }));

function isUnsetCredential(value) {
  const text = (value ?? '').trim();
  return text.length === 0 || text.startsWith('your-') || text.includes('path/to/');
}

function initializeFirebaseAdmin() {
  if (getApps().length > 0) {
    return true;
  }

  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  if (serviceAccountPath && !isUnsetCredential(serviceAccountPath)) {
    const resolvedPath = path.isAbsolute(serviceAccountPath)
      ? serviceAccountPath
      : path.resolve(process.cwd(), serviceAccountPath);

    if (fs.existsSync(resolvedPath)) {
      const serviceAccount = JSON.parse(fs.readFileSync(resolvedPath, 'utf8'));
      initializeApp({
        credential: cert(serviceAccount),
        projectId: process.env.FIREBASE_PROJECT_ID,
      });
      return true;
    }
  }

  const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const projectId = process.env.FIREBASE_PROJECT_ID;

  if (
    isUnsetCredential(privateKey) ||
    isUnsetCredential(clientEmail) ||
    isUnsetCredential(projectId)
  ) {
    console.warn(
      'Firebase Admin is not configured. Login routes stay unavailable until '
      + 'backend/.env has real Firebase credentials. AI lesson draft can still run.',
    );
    return false;
  }

  try {
    initializeApp({
      credential: cert({
        projectId,
        privateKey,
        clientEmail,
      }),
      projectId,
    });
    return true;
  } catch (error) {
    console.error(
      'Firebase Admin failed to start. AI lesson draft can still run.',
      error.message,
    );
    return false;
  }
}

const firebaseAdminReady = initializeFirebaseAdmin();

app.get('/api/health', (_req, res) => {
  res.json({
    ok: true,
    service: 'peer-learn-hub-backend',
    firebaseAdmin: firebaseAdminReady,
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
    
    // Fetch user role from Firestore
    const db = getFirestore();
    const userDoc = await db.collection('users').doc(decodedToken.uid).get();
    const userData = userDoc.exists ? userDoc.data() : {};
    
    return res.json({
      success: true,
      user: {
        uid: decodedToken.uid,
        email: decodedToken.email ?? null,
        name: decodedToken.name ?? null,
        picture: decodedToken.picture ?? null,
        provider: decodedToken.firebase?.sign_in_provider ?? 'firebase',
        role: userData.role || 'student',
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

app.post('/api/auth/register-moderator', async (req, res) => {
  try {
    const { idToken } = req.body ?? {};

    if (!idToken || typeof idToken !== 'string') {
      return res.status(400).json({
        success: false,
        message: 'Missing Firebase ID token.',
      });
    }

    // Verify Firebase token
    const decodedToken = await getAuth().verifyIdToken(idToken);
    const userId = decodedToken.uid;

    // Update user role in Firestore
    const db = getFirestore();
    await db.collection('users').doc(userId).set({
      role: 'moderator',
      updatedAt: new Date(),
    }, { merge: true });

    return res.json({
      success: true,
      message: 'User promoted to moderator successfully.',
      user: {
        uid: userId,
        email: decodedToken.email,
        role: 'moderator',
      },
    });
  } catch (error) {
    console.error('Moderator registration failed:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to register moderator.',
    });
  }
});

// Role-based login endpoint
app.post('/api/auth/login-with-role', async (req, res) => {
  try {
    const { idToken } = req.body ?? {};

    if (!idToken || typeof idToken !== 'string') {
      return res.status(400).json({
        success: false,
        message: 'Missing Firebase ID token.',
      });
    }

    const decodedToken = await getAuth().verifyIdToken(idToken);
    
    // Fetch user role from Firestore
    const db = getFirestore();
    const userDoc = await db.collection('users').doc(decodedToken.uid).get();
    
    if (!userDoc.exists) {
      return res.status(404).json({
        success: false,
        message: 'User not found in database.',
      });
    }

    const userData = userDoc.data();
    const userRole = userData.role || 'student';

    return res.json({
      success: true,
      user: {
        uid: decodedToken.uid,
        email: decodedToken.email ?? null,
        name: decodedToken.name ?? null,
        picture: decodedToken.picture ?? null,
        provider: decodedToken.firebase?.sign_in_provider ?? 'firebase',
        role: userRole,
      },
      redirectRoute: getRedirectRoute(userRole),
    });
  } catch (error) {
    console.error('Role-based login failed:', error);
    return res.status(401).json({
      success: false,
      message: 'Invalid or expired Firebase token.',
    });
  }
});

// Helper function to get redirect route based on role
function getRedirectRoute(role) {
  switch (role) {
    case 'moderator':
      return '/moderation';
    case 'teacher':
      return '/skill-provider';
    case 'student':
    default:
      return '/learning';
  }
}

// Middleware to check if user has required role
function requireRole(...allowedRoles) {
  return async (req, res, next) => {
    try {
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({
          success: false,
          message: 'Authorization header required.',
        });
      }

      const idToken = authHeader.substring(7);
      const decodedToken = await getAuth().verifyIdToken(idToken);
      
      const db = getFirestore();
      const userDoc = await db.collection('users').doc(decodedToken.uid).get();
      
      if (!userDoc.exists) {
        return res.status(404).json({
          success: false,
          message: 'User not found.',
        });
      }

      const userData = userDoc.data();
      const userRole = userData.role || 'student';

      if (!allowedRoles.includes(userRole)) {
        return res.status(403).json({
          success: false,
          message: `Access denied. Required role: ${allowedRoles.join(' or ')}`,
        });
      }

      req.user = {
        uid: decodedToken.uid,
        email: decodedToken.email,
        role: userRole,
      };
      next();
    } catch (error) {
      console.error('Role verification failed:', error);
      return res.status(401).json({
        success: false,
        message: 'Invalid authorization token.',
      });
    }
  };
}

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

// Example protected route for moderators only
app.get('/api/moderation/dashboard-stats', requireRole('moderator', 'admin'), async (req, res) => {
  try {
    const db = getFirestore();
    
    // Get verification requests stats
    const verificationSnapshot = await db.collection('verificationRequests')
      .where('status', '==', 'pending')
      .get();
    
    // Get reports stats
    const reportsSnapshot = await db.collection('reports')
      .where('status', '==', 'open')
      .get();
    
    return res.json({
      success: true,
      stats: {
        pendingVerifications: verificationSnapshot.size,
        openReports: reportsSnapshot.size,
      },
    });
  } catch (error) {
    console.error('Failed to fetch dashboard stats:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch dashboard statistics.',
    });
  }
});

// Example protected route for teachers and moderators
app.get('/api/lessons/my-lessons', requireRole('teacher', 'moderator', 'admin'), async (req, res) => {
  try {
    const db = getFirestore();
    const { uid } = req.user;
    
    const lessonsSnapshot = await db.collection('lessons')
      .where('authorId', '==', uid)
      .get();
    
    const lessons = lessonsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));
    
    return res.json({
      success: true,
      lessons,
    });
  } catch (error) {
    console.error('Failed to fetch lessons:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch lessons.',
    });
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

// AI Skill Exchange Match Suggestions endpoint (uses GEMINI_API_KEY from .env)
app.post('/api/ai/match-suggestions', async (req, res) => {
  try {
    const { prompt } = req.body ?? {};
    const apiKey = process.env.GEMINI_API_KEY;

    if (!apiKey) {
      return res.status(500).json({
        success: false,
        message: 'GEMINI_API_KEY is not configured in backend .env',
      });
    }

    if (!prompt) {
      return res.status(400).json({
        success: false,
        message: 'Missing prompt in request body.',
      });
    }

    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent?key=${apiKey}`;

    const geminiResponse = await fetch(geminiUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [
          {
            parts: [{ text: prompt }]
          }
        ],
        generationConfig: {
          temperature: 0.3,
          maxOutputTokens: 500,
        },
      }),
    });

    if (!geminiResponse.ok) {
      const errText = await geminiResponse.text();
      console.error('Gemini API returned error:', geminiResponse.status, errText);
      return res.status(geminiResponse.status).json({
        success: false,
        message: 'Gemini API call failed',
      });
    }

    const data = await geminiResponse.json();
    const rawText = data.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
    const cleanJson = rawText.replace(/```json/g, '').replace(/```/g, '').trim();

    let parsedList = [];
    try {
      parsedList = JSON.parse(cleanJson);
    } catch (parseErr) {
      console.warn('Could not parse Gemini JSON response:', cleanJson);
    }

    return res.json({
      success: true,
      suggestions: parsedList,
    });
  } catch (error) {
    console.error('Failed to generate AI match suggestions:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'AI suggestion generation failed.',
    });
  }
});

// AI Personalized Course Feed endpoint
app.post('/api/ai/recommendations', async (req, res) => {
  try {
    const { profile, courses } = req.body ?? {};
    const apiKey = process.env.GEMINI_API_KEY;

    if (!apiKey) {
      return res.status(500).json({ success: false, message: 'GEMINI_API_KEY missing' });
    }
    if (!Array.isArray(courses) || courses.length === 0) {
      return res.json({ success: true, feed: [] });
    }

    const prompt = `
You are an AI Learning Advisor for PeerLearn Hub. Build a personalized course feed
for the learner below that precisely matches their learning goal, current skill level,
interests, and recent search queries.

LEARNER PROFILE:
${JSON.stringify(profile, null, 2)}

AVAILABLE COURSES:
${JSON.stringify(courses, null, 2)}

Rules:
- Recommend at most 6 unique courses total.
- Match candidate courses against:
  1) Learner's goal (career/skill ambition)
  2) Learner's skill level (Beginner / Intermediate / Advanced)
  3) Learner's selected interests & topic tags
  4) Learner's past searches / search history
- Each recommendation MUST have a distinct "section" from:
  "goal", "skill_level", "interests", "past_search", "continue", "trending".
- "goal" = directly aligns with the learner's stated goal or career path.
- "skill_level" = ideally pitched at their current skill level tier.
- "interests" = matches their explicit topic interests.
- "past_search" = matches topics they recently searched for.
- "continue" = courses currently enrolled in with pending progress.
- "trending" = popular peer learning courses.
- Skip courses the learner has already completed (progress == 100).
- Give each a matchScore (integer 60-99) and a concise 1-sentence personalized reasoning explaining why it matches their goal, level, interests, or past searches.

Return ONLY a raw JSON object with this exact shape (no markdown fences):
{
  "feed": [
    {
      "courseId": "string",
      "section": "goal",
      "matchScore": 92,
      "reasoning": "1-sentence personal reason."
    }
  ]
}
`;

    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent?key=${apiKey}`;
    const geminiResponse = await fetch(geminiUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { temperature: 0.4, maxOutputTokens: 900 },
      }),
    });

    if (!geminiResponse.ok) {
      const errText = await geminiResponse.text();
      console.error('Gemini feed error:', geminiResponse.status, errText);
      return res.status(geminiResponse.status).json({ success: false, message: 'Gemini API failed' });
    }

    const data = await geminiResponse.json();
    const rawText = data.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
    const cleanJson = rawText.replace(/```json/g, '').replace(/```/g, '').trim();

    let parsed = { feed: [] };
    try {
      parsed = JSON.parse(cleanJson);
    } catch (e) {
      console.warn('Failed to parse feed JSON:', cleanJson);
    }

    return res.json({ success: true, feed: parsed.feed ?? [] });
  } catch (error) {
    console.error('AI feed error:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
});

// AI Similar Courses endpoint ("Students who viewed this also viewed...")
app.post('/api/ai/similar-courses', async (req, res) => {
  try {
    const { currentCourse, courses, coEnrolledCourseIds, coViewedCourseIds } = req.body ?? {};
    const apiKey = process.env.GEMINI_API_KEY;

    if (!apiKey) {
      return res.status(500).json({ success: false, message: 'GEMINI_API_KEY missing' });
    }
    if (!currentCourse || !Array.isArray(courses) || courses.length === 0) {
      return res.json({ success: true, similarCourses: [] });
    }

    const prompt = `
You are an expert Education Recommender AI for PeerLearn Hub.
A student is currently viewing the following course:
CURRENT COURSE:
${JSON.stringify(currentCourse, null, 2)}

ADDITIONAL BEHAVIORAL SIGNALS:
- Co-Enrolled Course IDs: ${JSON.stringify(coEnrolledCourseIds || [])}
- Frequently Co-Viewed Course IDs: ${JSON.stringify(coViewedCourseIds || [])}

AVAILABLE CANDIDATE COURSES:
${JSON.stringify(courses, null, 2)}

TASK:
Provide up to 4 similar courses under the theme "Students who viewed this also viewed...".
Consider:
1. Shared concepts, tags, and curriculum progression.
2. Behavioral co-views and co-enrollments.
3. Natural next steps or complementary skills.

Return ONLY a raw JSON object with this exact schema (no markdown formatting or fences):
{
  "similarCourses": [
    {
      "courseId": "string",
      "similarityScore": 92,
      "reasoning": "Concise 1-sentence reason why students viewing the current course also explore this."
    }
  ]
}
`;

    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent?key=${apiKey}`;
    const geminiResponse = await fetch(geminiUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { temperature: 0.3, maxOutputTokens: 600 },
      }),
    });

    if (!geminiResponse.ok) {
      const errText = await geminiResponse.text();
      console.error('Gemini similar courses error:', geminiResponse.status, errText);
      return res.status(geminiResponse.status).json({ success: false, message: 'Gemini API failed' });
    }

    const data = await geminiResponse.json();
    const rawText = data.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
    const cleanJson = rawText.replace(/```json/g, '').replace(/```/g, '').trim();

    let parsed = { similarCourses: [] };
    try {
      parsed = JSON.parse(cleanJson);
    } catch (e) {
      console.warn('Failed to parse similar courses JSON:', cleanJson);
    }

    return res.json({ success: true, similarCourses: parsed.similarCourses ?? [] });
  } catch (error) {
    console.error('Similar courses error:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
});

// AI Skill-gap recommendations endpoint
app.post('/api/ai/skill-gap', async (req, res) => {
  try {
    const { targetRole, currentSkills, completedCourses, candidateCourses } = req.body ?? {};
    const apiKey = process.env.GEMINI_API_KEY;

    if (!apiKey) {
      return res.status(500).json({ success: false, message: 'GEMINI_API_KEY missing' });
    }
    if (!targetRole || !Array.isArray(candidateCourses) || candidateCourses.length === 0) {
      return res.json({ success: true, data: null });
    }

    const prompt = `
You are an expert Career Advisor and Tech Skill-Gap Analyzer for PeerLearn Hub.
Analyze the student's background against their Target Role to identify mastered vs missing skills, compute a career readiness score (0-100%), and recommend matching courses to bridge the gap.

TARGET JOB ROLE: "${targetRole}"
STUDENT'S CURRENT SKILLS: ${JSON.stringify(currentSkills || [])}
COMPLETED COURSES: ${JSON.stringify(completedCourses || [])}
AVAILABLE COURSES TO BRIDGE GAPS:
${JSON.stringify(candidateCourses, null, 2)}

Instructions:
1. Identify 5-7 key skills required in industry for the target job role "${targetRole}".
2. Classify them into "masteredSkills" (what the student already has from current skills or completed courses) and "missingSkills" (the skill gap).
3. Compute a "readinessScore" percentage (integer 0-100).
4. Select up to 4 best courses that teach the missing skills.
5. For each recommended course provide:
   - "courseId": exact ID
   - "coveredSkills": list of missing skills covered
   - "matchScore": integer 70-98
   - "reasoning": 1 sentence explaining how it bridges their specific skill gap for the role.

Return ONLY a raw JSON object with this exact format (no markdown formatting or backticks):
{
  "targetRole": "${targetRole}",
  "readinessScore": 65,
  "masteredSkills": ["Skill A", "Skill B"],
  "missingSkills": ["Skill C", "Skill D", "Skill E"],
  "recommendedCourses": [
    {
      "courseId": "string",
      "coveredSkills": ["Skill C"],
      "matchScore": 92,
      "reasoning": "Closes your gap in Skill C needed for ${targetRole}."
    }
  ]
}
`;

    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent?key=${apiKey}`;
    const geminiResponse = await fetch(geminiUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { temperature: 0.3, maxOutputTokens: 800 },
      }),
    });

    if (!geminiResponse.ok) {
      const errText = await geminiResponse.text();
      console.error('Gemini skill-gap error:', geminiResponse.status, errText);
      return res.status(geminiResponse.status).json({ success: false, message: 'Gemini API failed' });
    }

    const data = await geminiResponse.json();
    const rawText = data.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
    const cleanJson = rawText.replace(/```json/g, '').replace(/```/g, '').trim();

    let parsed = null;
    try {
      parsed = JSON.parse(cleanJson);
    } catch (e) {
      console.warn('Failed to parse skill-gap JSON:', cleanJson);
    }

    return res.json({ success: true, data: parsed });
  } catch (error) {
    console.error('Skill-gap route error:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
});

const LESSON_DRAFT_CATEGORIES = [
  'Programming',
  'Design',
  'Business',
  'Languages',
  'Music',
  'Photography',
  'Cooking',
  'Other',
];
const LESSON_DRAFT_LEVELS = ['Beginner', 'Intermediate', 'Advanced'];
const LESSON_DRAFT_DURATIONS = ['30 minutes', '1 hour', '1.5 hours', '2 hours', '3 hours'];
const LESSON_DRAFT_TYPES = ['Online', 'In Person', 'Both'];

function pickLessonDraftValue(value, allowed, fallback) {
  if (typeof value !== 'string') return fallback;
  const match = allowed.find((item) => item.toLowerCase() === value.trim().toLowerCase());
  return match || fallback;
}

function asLessonDraftLines(value, limit) {
  const source = Array.isArray(value)
    ? value
    : typeof value === 'string'
      ? value.split('\n')
      : [];
  return source
    .map((item) => String(item).replace(/^[-*•\d.)\s]+/, '').trim())
    .filter((item) => item.length > 0 && !/^https?:\/\//i.test(item))
    .slice(0, limit);
}

async function requestGemini(apiKey, model, body, timeoutMs) {
  const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;
  const response = await fetch(geminiUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(timeoutMs),
  });
  return response;
}

function extractLessonDraftJson(rawText) {
  const clean = String(rawText).replace(/```json/gi, '').replace(/```/g, '').trim();
  try {
    return JSON.parse(clean);
  } catch (_) {
    const start = clean.indexOf('{');
    const end = clean.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return JSON.parse(clean.slice(start, end + 1));
    }
    throw new Error('Could not parse lesson draft JSON');
  }
}

// Drafts lesson copy and an optional 16:9 cover from a title.
// Availability, pricing, exchange type, location, and playlist URLs stay manual.
app.post('/api/ai/lesson-draft', async (req, res) => {
  try {
    const title = (req.body?.title ?? '').toString().trim();
    const includeText = req.body?.includeText !== false;
    const includeThumbnail = req.body?.includeThumbnail !== false;
    const apiKey = process.env.GEMINI_API_KEY;

    if (!apiKey) {
      return res.status(500).json({
        success: false,
        message: 'GEMINI_API_KEY is not configured in backend .env',
      });
    }

    if (title.length < 3) {
      return res.status(400).json({
        success: false,
        message: 'A lesson title is required.',
      });
    }

    let draft = null;
    if (includeText) {
      const prompt = `
You are helping a teacher draft a peer-learning lesson on PeerLearnHub.
Use only the lesson title. Do not invent a price, schedule, meeting link, exchange type, or YouTube URL.

Title: "${title}"

Return ONLY raw JSON with this shape:
{
  "description": "2 to 3 sentences about what the learner will do",
  "learningOutcomes": ["short outcome", "short outcome", "short outcome"],
  "category": "Programming | Design | Business | Languages | Music | Photography | Cooking | Other",
  "skillLevel": "Beginner | Intermediate | Advanced",
  "duration": "30 minutes | 1 hour | 1.5 hours | 2 hours | 3 hours",
  "lessonType": "Online | In Person | Both",
  "learningMaterials": ["resource name", "resource name"]
}

Rules:
- category, skillLevel, duration, and lessonType must be exactly one of the listed values.
- learningOutcomes: 3 to 5 specific results, no numbering.
- learningMaterials: 3 to 4 resource names only. No URLs.
- Do not include availability, price, location, or video links.
`;

      const textModels = ['gemini-3.5-flash-lite', 'gemini-3.8-flash', 'gemini-3.5-flash'];
      let geminiResponse = null;
      for (const model of textModels) {
        try {
          const response = await requestGemini(apiKey, model, {
            contents: [{ parts: [{ text: prompt }] }],
            generationConfig: {
              temperature: 0.4,
              maxOutputTokens: 1200,
            },
          }, 25000);
          if (response.ok) {
            geminiResponse = response;
            break;
          }
          const errText = await response.text();
          console.error('Lesson draft text error:', model, response.status, errText);
          geminiResponse = response;
        } catch (error) {
          console.error('Lesson draft text error:', model, error);
        }
      }

      if (!geminiResponse?.ok) {
        return res.status(geminiResponse?.status || 502).json({
          success: false,
          message: 'Could not draft the lesson details.',
        });
      }

      const data = await geminiResponse.json();
      const rawText = data.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
      let parsed;
      try {
        parsed = extractLessonDraftJson(rawText);
      } catch (parseError) {
        console.warn('Could not parse lesson draft JSON:', rawText);
        return res.status(502).json({
          success: false,
          message: 'Could not read the AI lesson draft.',
        });
      }

      if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
        return res.status(502).json({
          success: false,
          message: 'Could not read the AI lesson draft.',
        });
      }

      const description = (parsed.description ?? '').toString().trim();
      const outcomes = asLessonDraftLines(parsed.learningOutcomes, 5);
      const materials = asLessonDraftLines(parsed.learningMaterials, 4);
      if (!description || outcomes.length === 0) {
        return res.status(502).json({
          success: false,
          message: 'The AI lesson draft was incomplete.',
        });
      }

      draft = {
        description,
        learningOutcomes: outcomes,
        category: pickLessonDraftValue(parsed.category, LESSON_DRAFT_CATEGORIES, 'Other'),
        skillLevel: pickLessonDraftValue(parsed.skillLevel, LESSON_DRAFT_LEVELS, 'Beginner'),
        duration: pickLessonDraftValue(parsed.duration, LESSON_DRAFT_DURATIONS, '1 hour'),
        lessonType: pickLessonDraftValue(parsed.lessonType, LESSON_DRAFT_TYPES, 'Online'),
        learningMaterials: materials,
      };
    }

    let thumbnail = null;
    let thumbnailError = null;
    if (includeThumbnail) {
      try {
        const imagePrompt = `Create a clean 16:9 landscape cover illustration for a peer-learning lesson titled "${title}". Show a simple educational scene that matches the subject. No words, letters, numbers, logos, or watermarks. Soft lighting, modern flat style, uncluttered background.`;
        const imageModels = ['gemini-3.1-flash-image', 'gemini-2.5-flash-image'];
        for (const model of imageModels) {
          try {
            const imageResponse = await requestGemini(apiKey, model, {
              contents: [{ parts: [{ text: imagePrompt }] }],
              generationConfig: {
                responseModalities: ['IMAGE'],
                imageConfig: { aspectRatio: '16:9' },
              },
            }, 40000);
            if (!imageResponse.ok) {
              const errText = await imageResponse.text();
              console.error('Lesson thumbnail error:', model, imageResponse.status, errText);
              if (imageResponse.status === 429) {
                thumbnailError =
                  'Lesson text was filled. Thumbnail generation is not included on the free Gemini plan.';
              }
              continue;
            }
            const imageData = await imageResponse.json();
            const parts = imageData.candidates?.[0]?.content?.parts ?? [];
            const imagePart = parts.find((part) => part.inlineData?.data || part.inline_data?.data);
            const inline = imagePart?.inlineData || imagePart?.inline_data;
            if (inline?.data) {
              thumbnail = {
                mimeType: inline.mimeType || inline.mime_type || 'image/png',
                data: inline.data,
              };
              break;
            }
          } catch (modelError) {
            console.error('Lesson thumbnail error:', model, modelError);
          }
        }
      } catch (imageError) {
        console.error('Lesson thumbnail generation error:', imageError);
      }
    }

    if (!draft && !thumbnail) {
      return res.status(502).json({
        success: false,
        message: thumbnailError
          || (includeText
            ? 'Could not draft the lesson details.'
            : 'Could not generate a lesson thumbnail.'),
      });
    }

    return res.json({
      success: true,
      draft,
      thumbnail,
      thumbnailError,
    });
  } catch (error) {
    console.error('Lesson draft route error:', error);
    return res.status(500).json({
      success: false,
      message: 'Could not draft the lesson details.',
    });
  }
});

app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Route not found: ${req.method} ${req.originalUrl}`,
  });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`PeerLearnHub backend listening on http://0.0.0.0:${port} (and http://10.0.2.2:${port} for Android emulator)`);
  console.log(`Environment: ${process.env.NODE_ENV === 'production' ? 'PRODUCTION' : 'DEVELOPMENT'}`);
});
