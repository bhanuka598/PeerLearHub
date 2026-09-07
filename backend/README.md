# PeerLearnHub Backend

This folder contains the Express API that validates Firebase ID tokens used by the Flutter app.

## Quick start

1. Install dependencies:
   npm install
2. Copy the sample environment file:
   cp .env.example .env
3. Set your Firebase project ID and service account location.
4. Start the server:
   npm start

## Endpoints

- GET /api/health
- POST /api/auth/verify-token
- POST /api/auth/password-reset/request
- POST /api/auth/password-reset/verify

Expected request body:

{
  "idToken": "<firebase-id-token>"
}

## Notes

The Flutter app sends the Firebase Google ID token after the Google sign-in step. The backend verifies it with Firebase Admin before accepting the user session.

## Password reset OTP

The password reset flow sends a six-digit OTP by email instead of a reset link. Configure SMTP in `backend/.env` using the values shown in `.env.example`:

```env
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-smtp-username
SMTP_PASSWORD=your-smtp-password
SMTP_FROM=PeerLearnHub <no-reply@example.com>
```

Start the backend before using Forgot Password. Codes expire after 10 minutes and are limited to five verification attempts. The OTP is stored only as a hash in the backend process and is removed after successful use or expiry.

## Role switching

Roles are session-level UI state in the Flutter app and are not stored as Firebase custom claims. After signing in, use the role switcher in the app bar or dashboard header to move between Student and Teacher mode.

Both modes can learn courses and create courses. Completing a course does not permanently change the account role; a student can switch to Teacher mode whenever they are ready to teach, and a teacher can switch back to Student mode to learn.
