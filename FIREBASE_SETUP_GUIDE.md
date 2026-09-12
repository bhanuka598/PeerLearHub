# Firebase Backend Setup for Moderation Module

## Current Status ✅
- ✅ Firebase packages installed
- ✅ Firebase initialized in main.dart
- ✅ Services created with mock data
- ⏳ **NEXT: Create Firestore collections and switch to real data**

---

## 🚀 Quick Actions - Do This Now

### ✅ Step 1: Create Firestore Collections
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **PeerLearnHub**
3. Click **Firestore Database** in left menu
4. Click **Start Collection**
   - Collection ID: `verificationRequests`
   - Click **Next**
   - Add first document (use Auto-ID)
   - Add fields as shown in "Test Data" section below
5. Repeat for `reports` collection

### ✅ Step 2: Switch to Real Firebase
Open these 2 files and change `useMockData = true` to `false`:
1. `lib/features/moderation/services/verification_service.dart` (line 6)
2. `lib/features/moderation/services/moderation_service.dart` (line 6)

### ✅ Step 3: Run and Test
```bash
flutter run
```

---

## 📋 Detailed Setup Instructions

## Step 1: Firebase Console Setup

### 1.1 Create Collections in Firestore

Go to Firebase Console → Firestore Database → Start Collection

#### Collection 1: `verificationRequests`
```
Document ID: Auto-ID
Fields:
  - userId: string
  - userName: string
  - userProfileImage: string (optional)
  - verificationType: string ("identity" or "skill")
  - status: string ("pending", "approved", "rejected")
  - submittedAt: timestamp
  - reviewedAt: timestamp (optional)
  - reviewedBy: string (optional)
  - rejectionReason: string (optional)
  
  // For Identity Verification
  - fullName: string (optional)
  - identityDocumentUrl: string (optional)
  
  // For Skill Verification
  - skillName: string (optional)
  - experienceDescription: string (optional)
  - evidenceUrls: array (optional)
  - portfolioUrl: string (optional)
```

**Sample Document:**
```json
{
  "userId": "user_001",
  "userName": "Sarah Johnson",
  "userProfileImage": null,
  "verificationType": "skill",
  "skillName": "Flutter Development",
  "experienceDescription": "5 years of experience building mobile applications",
  "evidenceUrls": ["https://storage.googleapis.com/...", "..."],
  "portfolioUrl": "https://github.com/sarahjohnson",
  "status": "pending",
  "submittedAt": Firestore.Timestamp.now(),
  "reviewedAt": null,
  "reviewedBy": null,
  "rejectionReason": null
}
```

#### Collection 2: `reports`
```
Document ID: Auto-ID
Fields:
  - reportedBy: string
  - reporterName: string (optional)
  - reportedUserId: string
  - reportedUserName: string (optional)
  - relatedContentId: string (optional)
  - reason: string ("spam", "harassment", "unsafeLocation", "inappropriateContent", "fraudScam", "other")
  - description: string
  - severity: string ("low", "medium", "high")
  - status: string ("open", "underReview", "resolved", "dismissed")
  - createdAt: timestamp
  - reviewedAt: timestamp (optional)
  - reviewedBy: string (optional)
  - resolutionNote: string (optional)
```

**Sample Document:**
```json
{
  "reportedBy": "user_101",
  "reporterName": "John Smith",
  "reportedUserId": "user_202",
  "reportedUserName": "Spam Account",
  "relatedContentId": "post_123",
  "reason": "spam",
  "description": "User is posting promotional content repeatedly",
  "severity": "high",
  "status": "open",
  "createdAt": Firestore.Timestamp.now(),
  "reviewedAt": null,
  "reviewedBy": null,
  "resolutionNote": null
}
```

#### Collection 3: `moderationLogs` (Optional - for audit trail)
```
Document ID: Auto-ID
Fields:
  - moderatorId: string
  - moderatorName: string
  - actionType: string ("verification_approved", "verification_rejected", "report_resolved", "report_dismissed", "warning_issued", "user_banned")
  - targetId: string (verification ID or report ID)
  - targetUserId: string (affected user)
  - description: string
  - timestamp: timestamp
  - metadata: map (optional - any additional data)
```

### 1.2 Set Up Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is moderator
    function isModerator() {
      return request.auth != null && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'moderator';
    }
    
    // Verification Requests - Moderators can read/write
    match /verificationRequests/{requestId} {
      allow read: if request.auth != null && 
                     (request.auth.uid == resource.data.userId || isModerator());
      allow create: if request.auth != null;
      allow update, delete: if isModerator();
    }
    
    // Reports - Moderators can read/write
    match /reports/{reportId} {
      allow read: if request.auth != null && 
                     (request.auth.uid == resource.data.reportedBy || isModerator());
      allow create: if request.auth != null;
      allow update, delete: if isModerator();
    }
    
    // Moderation Logs - Only moderators can read/write
    match /moderationLogs/{logId} {
      allow read, write: if isModerator();
    }
    
    // Users collection (assuming it exists)
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 1.3 Set Up Firebase Storage Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Verification evidence files
    match /verification_evidence/{userId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Identity documents
    match /identity_documents/{userId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## Step 2: Switch Services to Real Firebase ⚠️ IMPORTANT

In your service files, change:
```dart
static bool useMockData = true;
```

To:
```dart
static bool useMockData = false;
```

**Files to update:**
1. `lib/features/moderation/services/verification_service.dart` (Line 6)
2. `lib/features/moderation/services/moderation_service.dart` (Line 6)

**How to do it:**
1. Open each file
2. Find the line `static bool useMockData = true;`
3. Change `true` to `false`
4. Save the file

---

## Step 3: Test Your Setup

Run the app after creating test data:
```bash
flutter run
```

You should see:
- ✅ Dashboard loads with data from Firestore
- ✅ Verification requests appear
- ✅ Reports appear
- ✅ Actions (approve/reject) update Firestore

---

## Step 4: Create Test Data in Firestore (Optional)

### Create Test Verification Requests (Run in Firebase Console)

```javascript
// Go to Firestore → verificationRequests → Add Document

// Document 1: Pending Skill Verification
{
  userId: "user_001",
  userName: "Sarah Johnson",
  userProfileImage: null,
  verificationType: "skill",
  skillName: "Flutter Development",
  experienceDescription: "5 years of experience building mobile applications with Flutter",
  evidenceUrls: [],
  portfolioUrl: "https://github.com/sarahjohnson",
  status: "pending",
  submittedAt: firebase.firestore.Timestamp.now(),
  reviewedAt: null,
  reviewedBy: null,
  rejectionReason: null
}

// Document 2: Pending Identity Verification
{
  userId: "user_002",
  userName: "Michael Chen",
  userProfileImage: null,
  verificationType: "identity",
  fullName: "Michael Chen",
  identityDocumentUrl: "https://example.com/docs/id_sample.jpg",
  status: "pending",
  submittedAt: firebase.firestore.Timestamp.now(),
  reviewedAt: null,
  reviewedBy: null,
  rejectionReason: null
}
```

### Create Test Reports

```javascript
// Document 1: Open High Severity Report
{
  reportedBy: "user_101",
  reporterName: "John Smith",
  reportedUserId: "user_202",
  reportedUserName: "Spam Account",
  relatedContentId: "post_123",
  reason: "spam",
  description: "User is posting promotional content repeatedly in multiple groups",
  severity: "high",
  status: "open",
  createdAt: firebase.firestore.Timestamp.now(),
  reviewedAt: null,
  reviewedBy: null,
  resolutionNote: null
}

// Document 2: Open Medium Severity Report
{
  reportedBy: "user_103",
  reporterName: "Maria Garcia",
  reportedUserId: "user_204",
  reportedUserName: "Tom Parker",
  relatedContentId: "listing_789",
  reason: "unsafeLocation",
  description: "Meeting location seems suspicious and in an isolated area",
  severity: "medium",
  status: "open",
  createdAt: firebase.firestore.Timestamp.now(),
  reviewedAt: null,
  reviewedBy: null,
  resolutionNote: null
}
```

---

## Step 5: Firestore Indexes (If needed)

If you get errors about missing indexes, Firebase will provide a link to create them automatically.

Common indexes needed:
```
Collection: verificationRequests
  - status (Ascending) + submittedAt (Descending)

Collection: reports
  - status (Ascending) + createdAt (Descending)
  - severity (Ascending) + createdAt (Descending)
```

---

## Step 6: Storage Structure

Organize Firebase Storage like this:

```
gs://your-project.appspot.com/
├── verification_evidence/
│   ├── user_001/
│   │   ├── certificate1.pdf
│   │   └── portfolio_screenshot.png
│   └── user_002/
│       └── id_document.jpg
└── identity_documents/
    └── user_002/
        └── national_id.jpg
```

---

## Step 7: Upload Evidence Files (Helper Function)

Add this to your verification service:

```dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

Future<String?> uploadEvidenceFile(File file, String userId) async {
  try {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('verification_evidence')
        .child(userId)
        .child('${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}');
    
    await storageRef.putFile(file);
    final downloadUrl = await storageRef.getDownloadURL();
    return downloadUrl;
  } catch (e) {
    print('Error uploading file: $e');
    return null;
  }
}
```

---

## Testing Checklist

### Before Going Live:
- [ ] Firebase project created
- [ ] Firestore collections created
- [ ] Security rules configured
- [ ] Storage rules configured
- [ ] `google-services.json` added (Android)
- [ ] `GoogleService-Info.plist` added (iOS)
- [ ] Firebase initialized in main.dart
- [ ] `useMockData = false` in services
- [ ] Test data created in Firestore
- [ ] App can read verification requests
- [ ] App can read reports
- [ ] Approve verification works
- [ ] Reject verification works
- [ ] Update report status works
- [ ] Statistics display correctly

---

## Quick Commands

### Run Flutter App
```bash
flutter pub get
flutter run
```

### Clear Flutter Build (if issues)
```bash
flutter clean
flutter pub get
flutter run
```

---

## Troubleshooting

### Issue: Firebase not initialized
**Solution:** Ensure `await Firebase.initializeApp()` is in main.dart before runApp()

### Issue: Permission denied
**Solution:** Check Firestore security rules and ensure user is authenticated

### Issue: Data not showing
**Solution:** 
1. Check Firestore console - is data there?
2. Check `useMockData` is false
3. Check console for errors

### Issue: Can't upload files
**Solution:** Check Storage rules and ensure path matches your code

---

## Next Steps After Basic Setup

1. **Add Moderator Role Check** - Ensure only moderators can access
2. **Add Activity Logging** - Log all moderation actions
3. **Add Real-time Updates** - Use StreamBuilder for live data
4. **Add Notifications** - Notify users of verification results
5. **Add Analytics** - Track moderation metrics

---

## Contact

If you need help with Firebase setup, ask your team member responsible for Firebase configuration or consult Firebase documentation:
https://firebase.google.com/docs/flutter/setup
