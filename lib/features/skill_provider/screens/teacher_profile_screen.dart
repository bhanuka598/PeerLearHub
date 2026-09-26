import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
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
    _load();
  }

  @override
  void dispose() {
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

  String _dash(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? 'Not added yet' : text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: TealPageHeader(
        title: 'Teacher Profile',
        actions: [
          if (!_loading && _profile != null && !_saving)
            IconButton(
              icon: Icon(_editing ? Icons.close : Icons.edit_outlined),
              tooltip: _editing ? 'Cancel' : 'Edit',
              onPressed: () {
                if (_editing) {
                  _applyProfile(_profile!);
                  setState(() => _editing = false);
                } else {
                  setState(() => _editing = true);
                }
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _heroCard(),
                          const SizedBox(height: 16),
                          _detailsCard(),
                          const SizedBox(height: 16),
                          _skillsCard(),
                          if (_editing) ...[
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 48,
                              child: FilledButton(
                                onPressed: _saving ? null : _save,
                                child: Text(_saving ? 'Saving...' : 'Save'),
                              ),
                            ),
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

  Widget _heroCard() {
    final profile = _profile!;
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        children: [
          GestureDetector(
            onTap: _editing ? _pickPhoto : null,
            child: Stack(
              children: [
                ProfileAvatar(
                  size: 88,
                  imageUrl: _imageUrl,
                  initial: profile.displayName,
                ),
                if (_editing)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _editing ? _nameController.text.trim().isEmpty
                    ? profile.displayName
                    : _nameController.text.trim() : profile.displayName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              if (profile.isVerified) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.verified,
                  color: Colors.blue,
                  size: 22,
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 18),
              Text(
                profile.totalReviews == 0
                    ? ' No ratings yet'
                    : ' ${profile.overallRating.toStringAsFixed(1)}  ·  ${profile.totalReviews} reviews',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailsCard() {
    return _card(
      icon: Icons.badge_outlined,
      title: 'Teacher details',
      child: _editing
          ? Column(
              children: [
                TextFormField(
                  controller: _nameController,
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
                  ),
                ),
              ],
            )
          : Column(
              children: [
                _infoRow(Icons.person_outline, 'Name', _dash(_profile!.displayName)),
                _infoRow(Icons.mail_outline, 'Email', _dash(_profile!.email)),
                _infoRow(Icons.place_outlined, 'Location', _dash(_profile!.location)),
                _infoRow(Icons.info_outline, 'Bio', _dash(_profile!.bio), isLast: true),
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
              'No skills added yet. Request skill verification to add them!',
              style: TextStyle(color: AppTheme.textSecondary),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skills
                  .map(
                    (skill) => Chip(
                      avatar: const Icon(
                        Icons.verified,
                        size: 16,
                        color: Colors.green,
                      ),
                      label: Text(skill),
                      backgroundColor: AppTheme.iconBackground,
                    ),
                  )
                  .toList(),
            ),
          if (_editing) ...[
            const SizedBox(height: 16),
            const Text(
              'Verified skills cannot be manually added or deleted. Please submit a Skill Verification request from your main profile to add new skills.',
              style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.iconBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
