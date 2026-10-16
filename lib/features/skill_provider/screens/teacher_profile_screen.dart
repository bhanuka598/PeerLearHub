import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/app_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../moderation/screens/support_inbox_screen.dart';
import '../models/teacher_profile.dart';
import '../services/storage_service.dart';
import '../services/teacher_profile_service.dart';
import '../utils/pick_local_image.dart';
import '../utils/profile_image.dart';
import '../utils/provider_id_helper.dart';
import '../widgets/app_header.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  final _service = TeacherProfileService.instance;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();

  TeacherProfile? _profile;
  List<String> _skills = [];
  String? _imageUrl;
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onDraftChanged);
    _load();
  }

  void _onDraftChanged() {
    if (_editing && mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_onDraftChanged);
    _nameController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = await resolveProviderId();
    final profile = await _service.getProfile(uid);
    if (!mounted) return;
    _applyProfile(profile);
    setState(() {
      _profile = profile;
      _loading = false;
      _editing = false;
    });
  }

  void _applyProfile(TeacherProfile profile) {
    _nameController.text = profile.displayName;
    _emailController.text = profile.email ?? '';
    _locationController.text = profile.location ?? '';
    _bioController.text = profile.bio;
    _skills = List<String>.from(profile.verifiedSkills);
    _imageUrl = profile.profileImageUrl;
  }

  void _startEditing() {
    if (_profile == null) return;
    _applyProfile(_profile!);
    setState(() => _editing = true);
  }

  void _cancelEditing() {
    if (_profile == null) return;
    _applyProfile(_profile!);
    setState(() => _editing = false);
  }

  Future<void> _save() async {
    if (_profile == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      final uid = await ensureProviderId();
      final toSave = TeacherProfile(
        uid: uid,
        displayName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        location: _locationController.text.trim(),
        bio: _bioController.text.trim(),
        verifiedSkills: List<String>.from(_skills),
        profileImageUrl: _imageUrl,
        overallRating: _profile!.overallRating,
        completedSessions: _profile!.completedSessions,
        totalReviews: _profile!.totalReviews,
        isVerified: _profile!.isVerified,
      );
      await _service.updateProfile(toSave);
      if (!mounted) return;
      setState(() {
        _profile = toSave;
        _skills = List<String>.from(toSave.verifiedSkills);
        _imageUrl = toSave.profileImageUrl ?? _imageUrl;
        _editing = false;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save profile. Try again.')),
      );
    }
  }

  Future<void> _pickPhoto() async {
    final picked = await pickLocalImage();
    if (picked == null || _profile == null) return;
    final url = await StorageService.instance.uploadProfileAvatar(
      bytes: picked.bytes,
      fileName: picked.fileName,
    );
    if (!mounted) return;
    setState(() => _imageUrl = url ?? _imageUrl);
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text(
          'You will need to sign in again to manage lessons, bookings, and messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.teacherAccentCoral,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    AppAuth.instance.logout();
    context.go('/login');
  }

  Future<void> _confirmSwitchRole() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch to student'),
        content: const Text(
          'You can come back to teaching anytime from the role switcher.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay here'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Switch'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    AppAuth.instance.switchRole(AppUserRole.student);
    context.go('/learning');
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'PeerLearHub',
      applicationVersion: '1.0.0',
      applicationLegalese: 'Teach, learn, and exchange skills with peers.',
      children: const [
        SizedBox(height: 12),
        Text(
          'Manage your teaching profile, lessons, and learner messages from this account.',
        ),
      ],
    );
  }

  String get _displayName {
    if (_editing) {
      final draft = _nameController.text.trim();
      if (draft.isNotEmpty) return draft;
    }
    final saved = _profile?.displayName.trim() ?? '';
    return saved.isEmpty ? 'Teacher' : saved;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.teacherPageBackground,
      appBar: TealPageHeader(
        title: 'Profile',
        actions: [
          if (!_loading && _profile != null && !_saving)
            IconButton(
              icon: Icon(_editing ? Icons.close : Icons.edit_outlined),
              tooltip: _editing ? 'Cancel' : 'Edit profile',
              onPressed: _editing ? _cancelEditing : _startEditing,
            ),
        ],
      ),
      bottomNavigationBar: _editing ? _saveBar() : null,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _heroCard(),
                          const SizedBox(height: 16),
                          if (_editing) ...[
                            _editCard(),
                            const SizedBox(height: 16),
                            _skillsCard(),
                          ] else ...[
                            _aboutCard(),
                            const SizedBox(height: 16),
                            _detailsCard(),
                            const SizedBox(height: 16),
                            _skillsCard(),
                            const SizedBox(height: 22),
                            _settingsSection(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _saveBar() {
    return Material(
      color: Colors.white,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : _cancelEditing,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: AppTheme.primaryColor),
                    foregroundColor: AppTheme.primaryDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(_saving ? 'Saving...' : 'Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroCard() {
    final profile = _profile!;
    final location = _editing
        ? _locationController.text.trim()
        : (profile.location ?? '').trim();

    return Container(
      decoration: AppTheme.teacherCardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 168,
            child: Stack(
              children: [
                Container(
                  height: 108,
                  decoration: const BoxDecoration(
                    gradient: AppTheme.teacherHeaderGradient,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 58,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _editing ? _pickPhoto : null,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            children: [
                              ProfileAvatar(
                                size: 96,
                                imageUrl: _imageUrl,
                                initial: _displayName,
                              ),
                              if (_editing)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_outlined,
                                      size: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _displayName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (profile.isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified,
                        color: Color(0xFF1D9BF0),
                        size: 20,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _pill(
                      Icons.cast_for_education_outlined,
                      'Skill provider',
                    ),
                    if (location.isNotEmpty)
                      _pill(Icons.place_outlined, location),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _statTile(
                        profile.totalReviews == 0
                            ? '—'
                            : profile.overallRating.toStringAsFixed(1),
                        'Rating',
                        Icons.star_rounded,
                        AppTheme.teacherAccentAmber,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statTile(
                        '${profile.totalReviews}',
                        'Reviews',
                        Icons.rate_review_outlined,
                        AppTheme.teacherAccentIndigo,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statTile(
                        '${profile.completedSessions}',
                        'Sessions',
                        Icons.event_available_outlined,
                        AppTheme.teacherAccentEmerald,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.iconBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryDark),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _aboutCard() {
    final bio = (_profile!.bio).trim();
    return _card(
      icon: Icons.notes_outlined,
      title: 'About',
      child: bio.isEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add a short bio so learners know your experience and how you teach.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: _startEditing,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Add bio'),
                ),
              ],
            )
          : Text(
              bio,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                height: 1.45,
                fontSize: 15,
              ),
            ),
    );
  }

  Widget _detailsCard() {
    return _card(
      icon: Icons.badge_outlined,
      title: 'Contact',
      child: Column(
        children: [
          _detailTile(
            Icons.person_outline,
            'Name',
            _displayName,
          ),
          _detailTile(
            Icons.mail_outline,
            'Email',
            _filled(_profile!.email),
          ),
          _detailTile(
            Icons.place_outlined,
            'Location',
            _filled(_profile!.location),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _editCard() {
    return _card(
      icon: Icons.edit_outlined,
      title: 'Edit profile',
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Full name'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _locationController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Location',
              hintText: 'City or teaching location',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _bioController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Bio',
              hintText: 'Tell students about your teaching experience',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _skillsCard() {
    return _card(
      icon: Icons.verified_outlined,
      title: 'Skills',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_skills.isEmpty)
            const Text(
              'No verified skills yet. Request skill verification from your learner profile to add them.',
              style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skills
                  .map(
                    (skill) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.iconBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified,
                            size: 16,
                            color: AppTheme.teacherAccentEmerald,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            skill,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          if (_editing) ...[
            const SizedBox(height: 14),
            const Text(
              'Verified skills stay linked to your verification requests. They cannot be added or removed from this form.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _settingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _settingsGroup(
          'Account',
          [
            _SettingAction(
              icon: Icons.edit_outlined,
              color: AppTheme.primaryColor,
              title: 'Edit profile',
              subtitle: 'Name, photo, location, and bio',
              onTap: _startEditing,
            ),
            _SettingAction(
              icon: Icons.notifications_outlined,
              color: AppTheme.teacherAccentAmber,
              title: 'Notifications',
              subtitle: 'Reminders and teaching alerts',
              onTap: () => context.push('/notifications'),
            ),
            _SettingAction(
              icon: Icons.lock_outline,
              color: AppTheme.teacherAccentIndigo,
              title: 'Password',
              subtitle: 'Reset the password for this account',
              onTap: () => context.push('/forgot-password'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _settingsGroup(
          'Teaching',
          [
            _SettingAction(
              icon: Icons.menu_book_outlined,
              color: AppTheme.teacherAccentEmerald,
              title: 'My lessons',
              subtitle: 'Listings you have published',
              onTap: () => context.push('/skill-provider/my-lessons'),
            ),
            _SettingAction(
              icon: Icons.pending_actions_outlined,
              color: AppTheme.teacherAccentSky,
              title: 'Bookings',
              subtitle: 'Learner requests waiting on you',
              onTap: () => context.push('/skill-provider/bookings'),
            ),
            _SettingAction(
              icon: Icons.chat_bubble_outline,
              color: AppTheme.teacherAccentIndigo,
              title: 'Messages',
              subtitle: 'Conversations with learners',
              onTap: () => context.push('/skill-provider/messages'),
            ),
            _SettingAction(
              icon: Icons.star_outline,
              color: AppTheme.teacherAccentAmber,
              title: 'Reviews',
              subtitle: 'Feedback from completed sessions',
              onTap: () => context.push('/skill-provider/reviews'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _settingsGroup(
          'Preferences',
          [
            _SettingAction(
              icon: Icons.swap_horiz,
              color: AppTheme.teacherAccentViolet,
              title: 'Switch to student',
              subtitle: 'Open the learning side of your account',
              onTap: _confirmSwitchRole,
            ),
          ],
        ),
        const SizedBox(height: 18),
        _settingsGroup(
          'Support',
          [
            _SettingAction(
              icon: Icons.support_agent_outlined,
              color: AppTheme.primaryColor,
              title: 'Help & support',
              subtitle: 'Reports and support inbox',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SupportInboxScreen(),
                  ),
                );
              },
            ),
            _SettingAction(
              icon: Icons.info_outline,
              color: AppTheme.textSecondary,
              title: 'About PeerLearHub',
              subtitle: 'Version 1.0.0',
              onTap: _showAbout,
            ),
          ],
        ),
        const SizedBox(height: 18),
        _settingsGroup(
          'Session',
          [
            _SettingAction(
              icon: Icons.logout,
              color: AppTheme.teacherAccentCoral,
              title: 'Sign out',
              subtitle: 'Leave this device',
              destructive: true,
              onTap: _confirmSignOut,
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'PeerLearHub  ·  Teacher account',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _settingsGroup(String title, List<_SettingAction> actions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: AppTheme.teacherCardDecoration,
          child: Column(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                _settingTile(actions[i]),
                if (i != actions.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 68,
                    color: Color(0xFFE6EFED),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _settingTile(_SettingAction action) {
    final titleColor =
        action.destructive ? AppTheme.teacherAccentCoral : AppTheme.textPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(AppTheme.teacherCardRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(action.icon, color: action.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: action.destructive
                    ? AppTheme.teacherAccentCoral
                    : const Color(0xFFB0BAB6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: AppTheme.teacherCardDecoration,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.iconBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _detailTile(
    IconData icon,
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.iconBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _filled(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? 'Not added yet' : text;
  }
}

class _SettingAction {
  const _SettingAction({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;
}
