# Verification & Moderation Management Module

**Member 4 - Individual Contribution**

This module provides a complete Verification & Moderation system for PeerLearn Hub, allowing moderators to review verification requests and manage reported content.

---

## 📦 Module Overview

### Purpose
Keep PeerLearn Hub trustworthy and safe by providing moderators with tools to:
- Review and approve/reject user verification requests (Identity & Skill)
- Manage flagged/reported content
- Monitor moderation activity through a centralized dashboard

### Features Implemented

#### ✅ Core Features (Sprint 1 Complete)
1. **Moderator Dashboard**
   - Summary statistics for verifications and reports
   - Quick action cards for navigation
   - Real-time data updates

2. **Verification Management**
   - View all verification requests with filtering
   - Review verification details
   - Approve verification requests
   - Reject with custom reason selection
   - Support for Identity and Skill verification types

3. **Report Management**
   - View all reported content
   - Filter by status and severity
   - Review report details
   - Mark reports as Under Review/Resolved/Dismissed
   - Optional resolution notes

4. **User Experience**
   - Clean, modern UI with PeerLearn Hub theme
   - Mobile-responsive design
   - Loading states, error handling, empty states
   - Pull-to-refresh functionality

---

## 🗂️ Project Structure

```
lib/
├── main.dart                                    # App entry point
├── core/
│   ├── constants/
│   │   └── app_colors.dart                     # Color palette
│   └── theme/
│       └── app_theme.dart                       # App theme configuration
└── features/
    └── moderation/
        ├── models/
        │   ├── verification_request.dart        # Verification data model
        │   └── moderation_report.dart           # Report data model
        ├── services/
        │   ├── verification_service.dart        # Verification business logic
        │   └── moderation_service.dart          # Report business logic
        ├── widgets/
        │   ├── stat_card.dart                   # Reusable stat card
        │   ├── navigation_card.dart             # Navigation card widget
        │   ├── verification_card.dart           # Verification list item
        │   └── report_card.dart                 # Report list item
        └── screens/
            ├── moderator_dashboard_screen.dart  # Main dashboard
            ├── verification_requests_screen.dart # Verification list
            ├── verification_details_screen.dart  # Verification details
            ├── reports_screen.dart              # Reports list
            └── report_details_screen.dart       # Report details
```

---

## 🚀 Setup & Installation

### 1. Install Dependencies

Open a terminal in the project root and run:

```bash
flutter pub get
```

This will install:
- `firebase_core` - Firebase initialization
- `cloud_firestore` - Firestore database
- `firebase_auth` - Firebase authentication
- `firebase_storage` - File storage
- `intl` - Date formatting

### 2. Run the Application

```bash
flutter run
```

The app will launch directly to the Moderator Dashboard.

---

## 🎨 Theme & Design

### Color Palette
- **Primary Teal**: `#0F766E` - Main actions, app bar
- **Primary Light**: `#CCFBF1` - Backgrounds, highlights
- **Secondary Green**: `#22C55E` - Secondary actions
- **Success/Approved**: `#16A34A` - Green
- **Pending/Warning**: `#F59E0B` - Amber
- **Rejected/Error**: `#DC2626` - Red

### Design Principles
- Clean and modern interface
- Mobile-first responsive design
- Intuitive navigation
- Clear visual hierarchy
- Consistent spacing and typography

---

## 🔥 Firebase Integration

### Current State: Mock Data Mode
The module is currently running with **mock data** to allow development without Firebase configuration.

### Services Architecture
Both `verification_service.dart` and `moderation_service.dart` have:
```dart
static bool useMockData = true;
```

When Firebase is ready:
1. Set `useMockData = false` in both services
2. Ensure Firebase is initialized in `main.dart`
3. Services will automatically switch to Firestore

### Firestore Collections

#### `verificationRequests`
```
{
  userId: string
  userName: string
  userProfileImage: string?
  verificationType: "identity" | "skill"
  
  // Identity fields
  fullName: string?
  identityDocumentUrl: string?
  
  // Skill fields
  skillName: string?
  experienceDescription: string?
  evidenceUrls: string[]?
  portfolioUrl: string?
  
  status: "pending" | "approved" | "rejected"
  submittedAt: timestamp
  reviewedAt: timestamp?
  reviewedBy: string?
  rejectionReason: string?
}
```

#### `reports`
```
{
  reportedBy: string
  reporterName: string?
  reportedUserId: string
  reportedUserName: string?
  relatedContentId: string?
  reason: "spam" | "harassment" | "unsafeLocation" | "inappropriateContent" | "fraudScam" | "other"
  description: string
  severity: "low" | "medium" | "high"
  status: "open" | "underReview" | "resolved" | "dismissed"
  createdAt: timestamp
  reviewedAt: timestamp?
  reviewedBy: string?
  resolutionNote: string?
}
```

---

## 📱 User Flows

### Verification Approval Flow
1. Moderator opens Dashboard
2. Clicks "Verification Management" or "Pending Requests" stat
3. Filters by "Pending" to see new requests
4. Clicks a verification request
5. Reviews evidence and information
6. Chooses "Approve" or "Reject"
   - If Reject: Selects or enters reason
7. Confirmation shown, returns to list
8. Dashboard updates automatically

### Report Resolution Flow
1. Moderator opens Dashboard
2. Clicks "Report Management" or "Open Reports" stat
3. Views list of reports (filtered by status/severity)
4. Clicks a report to view details
5. Reviews report information
6. Takes action:
   - Mark as Under Review
   - Resolve (with optional note)
   - Dismiss (with optional note)
7. Confirmation shown, returns to list
8. Dashboard updates automatically

---

## 🔐 Authentication Integration

### Current: Mock Moderator Access
The module currently uses a mock moderator ID: `'mod_001'`

### Integration with Team Auth
When another team member completes authentication:

1. **Import auth service** in moderation screens
2. **Replace mock moderator ID** with:
   ```dart
   final currentUser = FirebaseAuth.instance.currentUser;
   final moderatorId = currentUser?.uid ?? 'unknown';
   ```
3. **Add role check** before allowing access to moderation screens
4. **Protect routes** to ensure only moderators can access

Example:
```dart
// In main.dart or routing
if (userRole == 'moderator') {
  return ModeratorDashboardScreen();
} else {
  return UnauthorizedScreen();
}
```

---

## 🧪 Testing Checklist

### ✅ Verification Management
- [x] Dashboard loads successfully
- [x] Verification statistics display correctly
- [x] Verification list shows all requests
- [x] Filters work (All, Pending, Approved, Rejected)
- [x] Verification details open correctly
- [x] Identity verification shows correct fields
- [x] Skill verification shows correct fields
- [x] Approve button works
- [x] Reject button requires reason
- [x] Status updates reflect in list
- [x] Empty states show appropriately

### ✅ Report Management
- [x] Reports list loads
- [x] Filters work (All, Open, Under Review, High Severity, etc.)
- [x] Report details open correctly
- [x] Status badges show correct colors
- [x] Severity indicators work
- [x] Mark as Under Review works
- [x] Resolve with note works
- [x] Dismiss with note works
- [x] Empty states show appropriately

### ✅ UI/UX
- [x] Theme applied correctly
- [x] Navigation flows work
- [x] Back button navigation
- [x] Loading states display
- [x] Error states handled
- [x] Responsive on various screen sizes
- [x] Pull-to-refresh works

---

## 🔄 State Management

Currently using **StatefulWidget with setState**.

### Why This Approach?
- Simple and appropriate for module size
- No external dependencies
- Easy for team to understand
- Follows existing project patterns

### Future Migration
If the team adopts Provider/Riverpod/Bloc:
1. Services are already separated from UI
2. Wrap services in state management solution
3. Replace setState calls with state updates
4. Minimal refactoring required

---

## 🚧 Future Enhancements (Post-Sprint 1)

### Advanced Moderation Actions
- [ ] Issue warning to users
- [ ] Temporarily suspend users
- [ ] Permanently ban users
- [ ] Moderation action history

### Announcements
- [ ] Create safety announcements
- [ ] Publish to all users
- [ ] Edit/deactivate announcements

### Activity Logs
- [ ] Track all moderation actions
- [ ] Searchable audit trail
- [ ] Export logs

### Improvements
- [ ] Search functionality
- [ ] Advanced filtering
- [ ] Bulk actions
- [ ] Email notifications
- [ ] In-app notifications

---

## 📝 Code Quality

### Features
- Clean architecture with separation of concerns
- Reusable widgets for consistency
- Proper error handling
- Type-safe enums for states
- Comprehensive models with Firestore integration
- Comments where logic is complex

### Best Practices
- Consistent naming conventions
- Proper disposal of controllers
- Async/await error handling
- Null safety throughout
- Responsive design patterns

---

## 🤝 Integration with Other Modules

### Dependencies on Other Team Members
- **Authentication Module**: Need user role to restrict access
- **User Profile Module**: May display user avatars/details
- **Firebase Setup**: Needs Firebase to be configured

### What Other Members Can Use
- **Theme & Colors**: `core/theme/` and `core/constants/`
- **Reusable Widgets**: Navigation cards, stat cards
- **Design Patterns**: Service layer architecture
- **Mock Data Pattern**: For development before Firebase

---

## 🐛 Troubleshooting

### Issue: Flutter command not found
**Solution**: Add Flutter to your PATH or run commands from Flutter installation directory

### Issue: Dependencies not installing
**Solution**: 
```bash
flutter clean
flutter pub get
```

### Issue: Firebase errors
**Solution**: Ensure `useMockData = true` in services for development without Firebase

### Issue: Hot reload not working
**Solution**: Stop app and run `flutter run` again

---

## 📞 Contact & Support

**Module Owner**: Member 4 - Verification & Moderation Management

For questions about this module:
- Check this README first
- Review code comments in service files
- Check model definitions for data structure

---

## ✅ Sprint 1 Completion Status

**Status**: ✅ **COMPLETE**

All Priority 1-9 features implemented and tested:
1. ✅ Moderator Dashboard
2. ✅ Verification Request List
3. ✅ Verification Details
4. ✅ Approve Verification
5. ✅ Reject Verification + rejection reason
6. ✅ Firestore integration (ready, using mock data)
7. ✅ Status handling/filtering
8. ✅ Reported Content List
9. ✅ Report Details and basic report status management

**Ready for**: Integration with team's authentication and Firebase setup

---

## 📄 License

Part of the PeerLearn Hub university group project.
