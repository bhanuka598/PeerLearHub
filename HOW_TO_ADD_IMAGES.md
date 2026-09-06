# How to Add Profile Images to Your Flutter App

## Method 1: Using Asset Images (Recommended for Demo/Testing)

### Step 1: Create Assets Folder
Create these folders in your project root:
```
PeerLearHub/
├── assets/
│   └── images/
│       ├── profile.jpg
│       ├── user1.jpg
│       ├── user2.jpg
│       └── logo.png
```

### Step 2: Update pubspec.yaml
Add the assets section:

```yaml
flutter:
  uses-material-design: true
  
  # Add this section:
  assets:
    - assets/images/
```

### Step 3: Add Images to Assets Folder
1. Find or create profile images (JPG or PNG)
2. Copy them to `assets/images/` folder
3. Name them appropriately (profile.jpg, user1.jpg, etc.)

### Step 4: Use in Code

**For Dashboard Profile Image:**
Replace this line in `moderator_dashboard_screen.dart`:
```dart
CircleAvatar(
  radius: 28,
  backgroundColor: AppColors.primaryTeal,
  backgroundImage: null, // Current
  child: const Text('N', ...),
),
```

With:
```dart
CircleAvatar(
  radius: 28,
  backgroundColor: AppColors.primaryTeal,
  backgroundImage: const AssetImage('assets/images/profile.jpg'),
  // Remove child when using backgroundImage
),
```

**For Profile Screen:**
In `moderator_profile_screen.dart`, replace:
```dart
CircleAvatar(
  radius: 50,
  backgroundColor: AppColors.primaryLight,
  child: const Text('M', ...),
),
```

With:
```dart
CircleAvatar(
  radius: 50,
  backgroundImage: const AssetImage('assets/images/profile.jpg'),
),
```

---

## Method 2: Using Network Images (For Real App with Backend)

### For images from a URL:

```dart
CircleAvatar(
  radius: 28,
  backgroundImage: NetworkImage('https://example.com/profile.jpg'),
  backgroundColor: AppColors.primaryTeal,
),
```

### With Error Handling:

```dart
CircleAvatar(
  radius: 28,
  backgroundColor: AppColors.primaryTeal,
  child: ClipOval(
    child: Image.network(
      'https://example.com/profile.jpg',
      width: 56,
      height: 56,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Text(
          'N',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        );
      },
    ),
  ),
),
```

---

## Method 3: Using Firebase Storage (For Production)

### Step 1: Upload Image to Firebase Storage
```dart
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

Future<String?> uploadProfileImage(File imageFile, String userId) async {
  try {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('profile_images')
        .child('$userId.jpg');
    
    await storageRef.putFile(imageFile);
    final downloadUrl = await storageRef.getDownloadURL();
    return downloadUrl;
  } catch (e) {
    print('Error uploading image: $e');
    return null;
  }
}
```

### Step 2: Store URL in Firestore
```dart
await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .update({
      'profileImageUrl': downloadUrl,
    });
```

### Step 3: Display Image
```dart
StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return CircleAvatar(
        radius: 28,
        backgroundColor: AppColors.primaryTeal,
        child: const Text('N'),
      );
    }
    
    final profileImageUrl = snapshot.data!.get('profileImageUrl') as String?;
    
    return CircleAvatar(
      radius: 28,
      backgroundColor: AppColors.primaryTeal,
      backgroundImage: profileImageUrl != null
          ? NetworkImage(profileImageUrl)
          : null,
      child: profileImageUrl == null
          ? const Text('N', style: TextStyle(color: Colors.white))
          : null,
    );
  },
)
```

---

## Method 4: Image Picker (Let User Choose)

### Add Dependencies:
```yaml
dependencies:
  image_picker: ^1.0.4
```

### Implementation:
```dart
import 'package:image_picker/image_picker.dart';

Future<void> pickProfileImage() async {
  final ImagePicker picker = ImagePicker();
  
  // Pick image from gallery
  final XFile? image = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 512,
    maxHeight: 512,
    imageQuality: 75,
  );
  
  if (image != null) {
    // Use the image
    setState(() {
      _profileImagePath = image.path;
    });
    
    // Or upload to Firebase Storage
    // final url = await uploadProfileImage(File(image.path), userId);
  }
}
```

---

## Quick Test Setup (Easiest for Now)

### Step 1: Create assets folder
```bash
mkdir -p assets/images
```

### Step 2: Download a sample profile image
- Go to https://via.placeholder.com/150
- Save as `profile.jpg` in `assets/images/`

Or use any square image you have.

### Step 3: Update pubspec.yaml
```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/
```

### Step 4: Run
```bash
flutter pub get
flutter run
```

---

## Where to Update Profile Images

1. **Dashboard Header** (`moderator_dashboard_screen.dart` line ~66)
   ```dart
   backgroundImage: const AssetImage('assets/images/profile.jpg'),
   ```

2. **Profile Screen** (`moderator_profile_screen.dart` line ~42)
   ```dart
   backgroundImage: const AssetImage('assets/images/profile.jpg'),
   ```

3. **Verification Cards** (if showing user avatars)
   ```dart
   backgroundImage: const AssetImage('assets/images/user_avatar.jpg'),
   ```

---

## Tips

- **Image Size**: Use 512x512 or 1024x1024 pixels for profile images
- **Format**: JPG (smaller file) or PNG (supports transparency)
- **Optimization**: Compress images before adding to assets
- **Fallback**: Always provide a fallback (Text initial) when image fails

---

## Current Implementation

Right now your app shows:
- **Letter 'N'** in dashboard (line 66-77 in dashboard screen)
- **Letter 'M'** in profile screen (line 42-54 in profile screen)

To use real images, just uncomment the `backgroundImage` line and comment out the `child` line.
