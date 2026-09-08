import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/moderation_report.dart';
import '../services/moderation_service.dart';
import '../widgets/report_card.dart';
import 'report_details_screen.dart';

class ReportsScreen extends StatefulWidget {
  final String? initialFilter;
  
  const ReportsScreen({
    super.key,
    this.initialFilter,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ModerationService _moderationService = ModerationService();
  
  String _selectedFilter = 'All';
  final List<String> _filterOptions = [
    'All',
    'Open',
    'Under Review',
    'High Severity',
    'Resolved',
    'Dismissed',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null) {
      _selectedFilter = widget.initialFilter!;
    }
  }

  Stream<List<ModerationReport>> _getFilteredReports() {
    switch (_selectedFilter) {
      case 'Open':
        return _moderationService.getReportsByStatus(ReportStatus.open);
      case 'Under Review':
        return _moderationService.getReportsByStatus(ReportStatus.underReview);
      case 'Resolved':
        return _moderationService.getReportsByStatus(ReportStatus.resolved);
      case 'Dismissed':
        return _moderationService.getReportsByStatus(ReportStatus.dismissed);
      case 'High Severity':
        return _moderationService.getReportsBySeverity(ReportSeverity.high);
      default:
        return _moderationService.getReports();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reported Content'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.primaryTeal,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filterOptions.length,
              itemBuilder: (context, index) {
                final filter = _filterOptions[index];
                final isSelected = filter == _selectedFilter;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    backgroundColor: Colors.white.withOpacity(0.2),
                    selectedColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primaryTeal : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    checkmarkColor: AppColors.primaryTeal,
                    side: BorderSide(
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<ModerationReport>>(
        stream: _getFilteredReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading reports',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final reports = snapshot.data ?? [];

          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No $_selectedFilter Reports',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedFilter == 'Open'
                        ? 'All clear! No open reports.'
                        : 'No reports found.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return ReportCard(
                report: report,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportDetailsScreen(
                        reportId: report.id,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
