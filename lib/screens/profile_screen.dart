import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:peer_learn_hub/core/auth/auth_service.dart';
import 'package:peer_learn_hub/core/widgets/role_switcher_button.dart';
import 'package:peer_learn_hub/features/moderation/models/verification_request.dart';
import 'package:peer_learn_hub/features/moderation/services/verification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _certificates = [];
  int _totalPoints = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final userDocRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userDocRef.get();
      final userDocument = userDoc.data() ?? <String, dynamic>{};

      final mergedUserData = <String, dynamic>{
        'uid': user.uid,
        'fullName': userDocument['fullName'] ?? user.displayName ?? 'User',
        'email': userDocument['email'] ?? user.email ?? 'No email provided',
        'role': userDocument['role'] ?? 'student',
        'learningGoal': userDocument['learningGoal'] ?? 'No learning goal set',
        'learningPoints': userDocument['learningPoints'] ?? 0,
        'photoURL': userDocument['photoURL'] ??
            userDocument['profileImageUrl'] ??
            user.photoURL,
        'bio': userDocument['bio'] ?? '',
        'location': userDocument['location'] ?? '',
        'phoneNumber': userDocument['phoneNumber'] ?? '',
        'createdAt': userDocument['createdAt'],
        'isVerified': userDocument['isVerified'] ?? false,
        'isIdentityVerified': userDocument['isIdentityVerified'] ?? false,
        'verifiedSkills': List<String>.from(userDocument['verifiedSkills'] ?? []),
      };

      final assignmentsSnapshot = await userDocRef
          .collection('assignments')
          .where('status', isEqualTo: 'submitted')
          .get();

      final certificates = <Map<String, dynamic>>[];
      for (final doc in assignmentsSnapshot.docs) {
        final data = doc.data();
        certificates.add({
          'courseId': data['courseId'] ?? 'Course',
          'description': data['description'] ?? 'Submitted assignment',
          'githubUrl': data['githubUrl'],
          'submittedAt': data['submittedAt'],
        });
      }

      final totalPoints = (mergedUserData['learningPoints'] is num)
          ? (mergedUserData['learningPoints'] as num).toInt()
          : 0;

      setState(() {
        _userData = mergedUserData;
        _certificates = certificates;
        _totalPoints = totalPoints;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Failed to load profile: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _signOut() async {
    await AuthService.instance.signOut();
    if (mounted) {
      // Navigation will be handled by the router's auth state
    }
  }

  void _showVerificationDialog(BuildContext context, String uid, String name, String? photoUrl, bool isIdentityVerified) {
    VerificationType type = VerificationType.skill;
    final textController1 = TextEditingController();
    final textController2 = TextEditingController();
    final textController3 = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Request Verification'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<VerificationType>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Verification Type'),
                    items: VerificationType.values
                        .where((t) => !isIdentityVerified || t != VerificationType.identity)
                        .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.displayName),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => type = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  if (type == VerificationType.skill) ...[
                    TextField(
                      controller: textController1,
                      decoration: const InputDecoration(labelText: 'Skill Name'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: textController2,
                      decoration: const InputDecoration(labelText: 'Experience Description'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: textController3,
                      decoration: const InputDecoration(labelText: 'Portfolio / Evidence URL (Optional)'),
                    ),
                  ] else ...[
                    TextField(
                      controller: textController1,
                      decoration: const InputDecoration(labelText: 'Full Name (as per ID)'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: textController2,
                      decoration: const InputDecoration(labelText: 'ID Document URL (Google Drive, etc.)'),
                    ),
                  ]
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submitting request...')));
                  await VerificationService().submitVerificationRequest(
                    userId: uid,
                    userName: name,
                    userProfileImage: photoUrl,
                    verificationType: type,
                    skillName: type == VerificationType.skill ? textController1.text : null,
                    experienceDescription: type == VerificationType.skill ? textController2.text : null,
                    portfolioUrl: type == VerificationType.skill && textController3.text.isNotEmpty ? textController3.text : null,
                    fullName: type == VerificationType.identity ? textController1.text : null,
                    identityDocumentUrl: type == VerificationType.identity ? textController2.text : null,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification requested successfully!')));
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = _userData?['fullName'] ?? user?.displayName ?? 'User';
    final email = _userData?['email'] ?? user?.email ?? 'No email provided';
    final role = (_userData?['role'] ?? 'student').toString();
    final learningGoal = _userData?['learningGoal'] ?? 'No learning goal set';
    final photoUrl = _userData?['photoURL'] as String? ?? user?.photoURL;
    final memberSince = _userData?['createdAt'];
    final bio = _userData?['bio']?.toString();
    final location = _userData?['location']?.toString();
    final isVerified = _userData?['isVerified'] == true;
    final isIdentityVerified = _userData?['isIdentityVerified'] == true;
    final verifiedSkills = List<String>.from(_userData?['verifiedSkills'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: const [RoleSwitcherButton()],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 42,
                                backgroundImage:
                                    photoUrl != null && photoUrl.isNotEmpty
                                        ? NetworkImage(photoUrl)
                                        : null,
                                child: photoUrl == null || photoUrl.isEmpty
                                    ? const Icon(Icons.person, size: 42)
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          displayName,
                                          style: Theme.of(context).textTheme.titleLarge,
                                        ),
                                        if (isVerified || isIdentityVerified) ...[
                                          const SizedBox(width: 6),
                                          const Icon(
                                            Icons.verified,
                                            color: Colors.blue,
                                            size: 20,
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      email,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        role.toUpperCase(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (bio != null && bio.isNotEmpty) ...[
                            Text(
                              'About',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(bio),
                            const SizedBox(height: 12),
                          ],
                          _InfoRow(
                            icon: Icons.flag_outlined,
                            label: 'Learning goal',
                            value: learningGoal,
                          ),
                          if (location != null && location.isNotEmpty)
                            _InfoRow(
                              icon: Icons.location_on_outlined,
                              label: 'Location',
                              value: location,
                            ),
                          if (memberSince != null)
                            _InfoRow(
                              icon: Icons.calendar_today_outlined,
                              label: 'Member since',
                              value: _formatDate(memberSince),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Learning Points',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$_totalPoints',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.stars_rounded,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Submitted Assignments',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (_certificates.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No submitted assignments yet. Complete courses and submit work to see them here.',
                        ),
                      ),
                    )
                  else
                    ..._certificates.map((cert) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.verified,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        cert['courseId'] ?? 'Assignment',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  cert['description'] ?? 'No description provided',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                if (cert['githubUrl'] != null &&
                                    cert['githubUrl'].toString().isNotEmpty)
                                  Row(
                                    children: [
                                      const Icon(Icons.link, size: 16),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          cert['githubUrl'],
                                          style: Theme.of(context).textTheme.bodySmall,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  'Submitted: ${_formatDate(cert['submittedAt'])}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        )),

                  const SizedBox(height: 24),
                  
                  if (verifiedSkills.isNotEmpty) ...[
                    Text(
                      'Verified Skills',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: verifiedSkills.map((skill) => Chip(
                        label: Text(skill),
                        backgroundColor: Colors.teal.withOpacity(0.1),
                        side: BorderSide.none,
                        avatar: const Icon(Icons.verified, size: 16, color: Colors.teal),
                      )).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  _VerificationStatusWidget(userId: user!.uid),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showVerificationDialog(context, user.uid, displayName, photoUrl, isIdentityVerified),
                      icon: const Icon(Icons.verified_user_outlined),
                      label: const Text('Request Verification'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _formatDate(dynamic date) {
    if (date is Timestamp) {
      return date.toDate().toString().split(' ')[0];
    } else if (date is DateTime) {
      return date.toString().split(' ')[0];
    }
    return 'Unknown date';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationStatusWidget extends StatelessWidget {
  final String userId;

  const _VerificationStatusWidget({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<VerificationRequest>>(
      stream: VerificationService().getVerificationRequestsByUserId(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final requests = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Verification Requests',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...requests.map((req) {
              final statusStr = req.status.name;
              final type = req.verificationType.name;
              final reason = req.rejectionReason;
              
              Color statusColor = Colors.orange;
              IconData statusIcon = Icons.pending_actions;
              String statusText = 'Pending';

              if (statusStr == 'approved') {
                statusColor = Colors.green;
                statusIcon = Icons.check_circle;
                statusText = 'Approved';
              } else if (statusStr == 'rejected') {
                statusColor = Colors.red;
                statusIcon = Icons.cancel;
                statusText = 'Rejected';
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(statusIcon, color: statusColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${type[0].toUpperCase()}${type.substring(1)} Verification',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (statusStr == 'rejected' && reason != null && reason.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Reason: $reason',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
