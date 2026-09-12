# Moderation Module - Complete Firebase Integration

## ✅ What's Been Integrated

### 1. Core Features (Already Working)
- ✅ **Verification Requests** - Read/Write from `verificationRequests` collection
- ✅ **Reports & Flags** - Read/Write from `reports` collection
- ✅ **Dashboard Statistics** - Real-time stats from both collections

### 2. Activity Tracking (NEW - Just Added)
- ✅ **Activity Log Screen** - Shows YOUR moderation actions in real-time
- ✅ **Moderation Actions Screen** - All actions with filters (Warnings, Bans, Dismissed)
- ✅ **Automatic Logging** - Every approve/reject/resolve creates a log entry

### 3. Analytics (NEW - Just Added)
- ✅ **Community Safety Screen** - Real-time trust index, report volume, top categories
- ✅ **Safety Alerts** - Automatic detection of high report volumes

---

## 🗄️ Firebase Collections Used

### 1. `verificationRequests` (Core)
**What it stores:** User skill/identity verification requests

**Fields:**
```
- userId: string
- userName: string
- verificationType: "skill" | "identity"
- skillName: string (optional)
- status: "pending" | "approved" | "rejected"
- submittedAt: timestamp
- reviewedAt: timestamp
- reviewedBy: string (moderator ID)
```

**Connected to:**
- Verification Requests Screen
- Verification Details Screen
- Dashboard stats

---

### 2. `reports` (Core)
**What it stores:** User reports and flags

**Fields:**
```
- reportedBy: string (reporter user ID)
- reportedUserId: string (reported user ID)
- reason: "spam" | "harassment" | "unsafeLocation" | "inappropriateContent" | "fraudScam"
- severity: "low" | "medium" | "high"
- status: "open" | "underReview" | "resolved" | "dismissed"
- description: string
- createdAt: timestamp
- reviewedBy: string (moderator ID)
```

**Connected to:**
- Reports Screen
- Report Details Screen
- Community Safety (analytics)
- Dashboard stats

---

### 3. `moderationLogs` (NEW - Auto-created)
**What it stores:** All moderation actions for audit trail

**Fields:**
```
- moderatorId: string
- moderatorName: string
- actionType: string (verification_approved, verification_rejected, report_resolved, etc.)
- targetId: string (ID of verification/report)
- targetUserId: string (affected user)
- description: string
- timestamp: timestamp
- metadata: map (additional data)
```

**Auto-created when:**
- ✅ You approve a verification → Creates log with `actionType: "verification_approved"`
- ✅ You reject a verification → Creates log with `actionType: "verification_rejected"`
- ✅ You resolve a report → Creates log with `actionType: "report_resolved"`
- ✅ You dismiss a report → Creates log with `actionType: "report_dismissed"`

**Connected to:**
- Activity Log Screen (your personal activity)
- Moderation Actions Screen (all actions with filters)

---

### 4. `users` (Shared - Used for analytics)
**What you read from it:**
- User trust scores (for Community Safety)
- Moderator role checking
- User profile data

**Connected to:**
- Community Safety Screen (trust distribution)
- Moderator Guard (role verification)

---

## 🔐 Required Firebase Security Rules

Add these to your Firestore Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is moderator
    function isModerator() {
      return request.auth != null && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'moderator';
    }
    
    // Users collection (shared with other modules)
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Lessons collection (shared with other modules)
    match /lessons/{lessonId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // MODERATION: Verification Requests
    match /verificationRequests/{requestId} {
      allow read, write: if isModerator();
    }
    
    // MODERATION: Reports
    match /reports/{reportId} {
      allow read, write: if isModerator();
    }
    
    // MODERATION: Activity Logs (audit trail)
    match /moderationLogs/{logId} {
      allow read, write: if isModerator();
    }
    
  }
}
```

---

## 📊 How Data Flows

### Approve Verification Flow:
```
1. User clicks "Approve" button
   ↓
2. VerificationService.approveVerificationRequest()
   ↓
3. Updates verificationRequests/{id}
   - Sets status = "approved"
   - Sets reviewedBy = moderatorId
   ↓
4. ActivityLogService.logAction()
   ↓
5. Creates moderationLogs/{auto-id}
   - actionType = "verification_approved"
   - description = "Approved skill verification for John"
   ↓
6. Activity Log Screen auto-updates (StreamBuilder)
```

### Report Resolution Flow:
```
1. User clicks "Resolve" button
   ↓
2. ModerationService.updateReportStatus()
   ↓
3. Updates reports/{id}
   - Sets status = "resolved"
   - Sets reviewedBy = moderatorId
   ↓
4. ActivityLogService.logAction()
   ↓
5. Creates moderationLogs/{auto-id}
   - actionType = "report_resolved"
   ↓
6. Activity Log + Community Safety auto-update
```

---

## 🔗 Screen Connections to Firebase

| Screen | Firebase Collections | Data Type |
|--------|---------------------|-----------|
| **Dashboard** | verificationRequests, reports | Stats (counts) |
| **Verification Requests** | verificationRequests | Real-time list |
| **Verification Details** | verificationRequests | Single document |
| **Reports** | reports | Real-time list |
| **Report Details** | reports | Single document |
| **Activity Log** | moderationLogs | Real-time filtered by moderatorId |
| **Moderation Actions** | moderationLogs | Real-time with action type filters |
| **Community Safety** | reports, users | Analytics (aggregated) |
| **Profile** | users, moderationLogs | User data + stats |

---

## 🎯 Dependencies on Other Team Members

### Your Module NEEDS Data From:
1. **User Management Module** (users collection)
   - ✅ User IDs, names, roles
   - ✅ Trust scores (for analytics)

2. **Lessons/Content Module** (lessons collection)
   - ✅ Lesson IDs for reports
   - ✅ Content that gets reported

### Other Modules NEED Data From You:
1. **User Profiles**
   - Should display verification badges (approved verifications)
   
2. **Lessons/Content**
   - Should hide/flag content with resolved reports

---

## 🧪 Testing Your Module

### 1. Create Test Data:

**Verification Request:**
```javascript
{
  userId: "0E4EV4FoDHPJdhVZSH73mDHeAu63",
  userName: "Tharusha",
  verificationType: "skill",
  skillName: "Flutter Development",
  status: "pending",
  submittedAt: firebase.firestore.Timestamp.now(),
}
```

**Report:**
```javascript
{
  reportedBy: "0E4EV4FoDHPJdhVZSH73mDHeAu63",
  reportedUserId: "NyQJ6nURpSk0X4vzzkn2",
  reason: "spam",
  severity: "high",
  status: "open",
  description: "Posting spam content",
  createdAt: firebase.firestore.Timestamp.now(),
}
```

### 2. Test Actions:
1. ✅ Approve a verification → Check Activity Log
2. ✅ Reject a verification → Check Activity Log
3. ✅ Resolve a report → Check Activity Log & Moderation Actions
4. ✅ Dismiss a report → Check Activity Log & Moderation Actions

### 3. Verify Auto-Creation:
- Open Firebase Console → `moderationLogs` collection
- Should see entries auto-created when you approve/reject/resolve

---

## 🚀 What Happens Automatically

1. **Activity Logging** - Every moderation action is logged
2. **Real-time Updates** - All screens use StreamBuilder for live data
3. **Statistics Calculation** - Dashboard stats calculated from Firebase
4. **Trust Index** - Calculated from report resolution rates
5. **Safety Alerts** - Auto-detected from high severity/volume reports

---

## 📝 Summary

**Your moderation module now has:**
- ✅ Complete Firebase integration
- ✅ Real-time data sync
- ✅ Automatic activity logging
- ✅ Analytics and safety monitoring
- ✅ Role-based access control

**All screens are connected to real Firebase data!** 🎉
