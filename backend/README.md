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
