import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../models/verification_request.dart';
import '../services/verification_service.dart';
import '../widgets/moderator_bottom_nav.dart';
import '../widgets/moderator_app_bar.dart';
import 'verification_details_screen.dart';

class VerificationRequestsScreen extends StatefulWidget {
  final String? initialFilter;
  
  const VerificationRequestsScreen({
    super.key,
    this.initialFilter,
  });

  @override
  State<VerificationRequestsScreen> createState() =>
      _VerificationRequestsScreenState();
}

class _VerificationRequestsScreenState
    extends State<VerificationRequestsScreen> {
  final VerificationService _verificationService = VerificationService();
  final TextEditingController _searchController = TextEditingController();
  
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final List<String> _filterOptions = ['All', 'Pending', 'Approved', 'Rejected'];

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null) {
      _selectedFilter = widget.initialFilter!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildAvatar(String? imageUrl, String userName, {double size = 60}) {
    if (imageUrl != null && imageUrl.trim().isNotEmpty && imageUrl.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallbackAvatar(userName, size),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: size,
              height: size,
              color: Colors.grey.shade100,
              child: Center(
                child: SizedBox(
                  width: size * 0.4,
                  height: size * 0.4,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
        ),
      );
    }
    return _fallbackAvatar(userName, size);
  }

  Widget _fallbackAvatar(String userName, double size) {
    final initial = userName.trim().isNotEmpty ? userName.trim()[0].toUpperCase() : 'U';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryTeal,
            const Color(0xFF0284C7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTeal.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.42,
          ),
        ),
      ),
    );
  }

  Stream<List<VerificationRequest>> _getFilteredRequests() {
    switch (_selectedFilter) {
      case 'Pending':
        return _verificationService.getVerificationRequestsByStatus(
            VerificationStatus.pending);
      case 'Approved':
        return _verificationService.getVerificationRequestsByStatus(
            VerificationStatus.approved);
      case 'Rejected':
        return _verificationService.getVerificationRequestsByStatus(
            VerificationStatus.rejected);
      default:
        return _verificationService.getVerificationRequests();
    }
  }

  Color _getStatusColor(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.pending:
        return Colors.orange;
      case VerificationStatus.approved:
        return Colors.green;
      case VerificationStatus.rejected:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: const ModeratorAppBar(),
      bottomNavigationBar: const ModeratorBottomNav(currentIndex: 1),
      body: SafeArea(
        child: Column(
          children: [
            // Row 1: Back arrow and Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Review queue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            
            // Row 2: Search bar and filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim().toLowerCase();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search requests by name, skill, or type...',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryTeal.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.tune, color: Colors.white, size: 20),
                      onPressed: () {
                         // Filter bottom sheet or logic
                      },
                      padding: const EdgeInsets.all(14),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.transparent,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filterOptions.map((filter) {
                    final isSelected = filter == _selectedFilter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: AppColors.primaryTeal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        side: BorderSide.none,
                        avatar: isSelected
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<VerificationRequest>>(
                stream: _getFilteredRequests(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Error loading requests',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final allRequests = snapshot.data ?? [];
                  final requests = _searchQuery.isEmpty
                      ? allRequests
                      : allRequests.where((req) {
                          final q = _searchQuery;
                          final name = req.userName.toLowerCase();
                          final fullName = (req.fullName ?? '').toLowerCase();
                          final skill = (req.skillName ?? '').toLowerCase();
                          final type = req.verificationType.displayName.toLowerCase();
                          return name.contains(q) || fullName.contains(q) || skill.contains(q) || type.contains(q);
                        }).toList();

                  if (requests.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty ? Icons.search_off : Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No requests matching "$_searchQuery"'
                                  : 'No $_selectedFilter Requests',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_searchQuery.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                icon: const Icon(Icons.clear, size: 16),
                                label: const Text('Clear search'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final request = requests[index];
                      final statusColor = _getStatusColor(request.status);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VerificationDetailsScreen(
                                    requestId: request.id,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  _buildAvatar(request.userProfileImage, request.userName, size: 56),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          request.userName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          request.verificationType == VerificationType.skill
                                              ? request.skillName ?? 'Skill verification'
                                              : 'Identity verification',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.star,
                                              size: 16,
                                              color: Colors.amber[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '5', // Keeping static as in reference
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.amber[600],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Icon(
                                              Icons.access_time_outlined,
                                              size: 16,
                                              color: Colors.grey[500],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              dateFormat.format(request.submittedAt),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                            const Spacer(),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: statusColor.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                request.status.displayName,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: statusColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey[400],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
