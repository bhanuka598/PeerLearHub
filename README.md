# PeerLearHub
Community Skill-Exchange &amp; Micro-Learning App

# 📖 Overview
PeerLearnHub is a community-driven mobile application designed to facilitate peer-to-peer skill exchange and micro-learning. The platform connects learners with local skill providers, enabling short, practical learning sessions that are affordable, flexible, and community-focused.

Built on Firebase as the primary backend solution, PeerLearnHub leverages Firebase's comprehensive suite of tools for authentication, real-time database, cloud functions, and push notifications, enabling rapid development and scalable deployment.

# 🎯 Project Vision
To create a trusted, safe, and efficient ecosystem where community members can freely exchange knowledge, build practical skills, and foster economic growth through peer-to-peer learning.

# 👥 Target User Groups
Persona	            Role	                Key Needs
Nirmal Fernando	    Skill Seeker	        Find relevant courses, track progress, earn certificates
Kavindu Perera	    Peer Teacher	        Create and manage short sessions, connect with learners
Priyantha Kumara	Skill Exchange Member	Quick, local skill swaps, flexible learning
Anusha Ranasinghe	Community Moderator	    Maintain safety, verify users, resolve disputes

# 🚀 Key Features
1. Skill-Seeker Learning Engine
Advanced search and filtering for skills and courses

Structured learning paths with video lessons

Interactive puzzles and assignments for knowledge assessment

Gamification with point rewards (5pts for perfect puzzles, 15pts for assignments)

Course completion certificates (generated via Firebase Cloud Functions)

2. Peer Teacher Session Management
Create and publish short skill-based sessions

Flexible session types: free, skill-swap, or small-fee

Online or face-to-face session options

Session scheduling with date/time availability

Upload learning materials (videos, notes, images, activities)

Real-time in-app messaging with Firestore

Booking management (accept, decline, reschedule)

3. Skill Exchange & Matching
Location-based discovery (using Firestore Geopoint queries)

Quick offer creation (under 2 minutes)

Direct exchange proposals

One-tap accept/decline for exchange requests

Session completion and peer rating system

4. Moderation & Safety Dashboard
Centralized moderation view for reports and flagged content

User verification (ID and skill verification)

Account sanctioning (warnings, suspensions, bans)

Report filtering by severity (Spam, Harassment, Unsafe Location)

Moderation audit logs and platform announcements

# 🛠️ Technology Stack
Frontend
Mobile Application: Flutter

State Management: BLOC

UI Framework: Material Design / Custom Components

Backend (Firebase Suite)
Authentication: Firebase Authentication (Email/Password, Google, Phone)

Database: Cloud Firestore (NoSQL, real-time, scalable)

File Storage: Firebase Storage (for images, videos, documents)

Cloud Functions: Firebase Cloud Functions (Node.js runtime)

Push Notifications: Firebase Cloud Messaging (FCM)

Analytics: Firebase Analytics & Crashlytics

Hosting: Firebase Hosting (for web dashboard/admin panel)

Remote Config: Firebase Remote Config (feature toggling)

Third-Party Services
Geolocation: Google Maps API / Geocoding API

Email Service: Firebase Extensions

Payment Gateway: Stripe 

