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

Expected request body:

{
  "idToken": "<firebase-id-token>"
}

## Notes

The Flutter app sends the Firebase Google ID token after the Google sign-in step. The backend verifies it with Firebase Admin before accepting the user session.

## Role switching

Roles are session-level UI state in the Flutter app and are not stored as Firebase custom claims. After signing in, use the role switcher in the app bar or dashboard header to move between Student and Teacher mode.

Both modes can learn courses and create courses. Completing a course does not permanently change the account role; a student can switch to Teacher mode whenever they are ready to teach, and a teacher can switch back to Student mode to learn.
