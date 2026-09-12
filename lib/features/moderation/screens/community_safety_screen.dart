import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/constants/app_colors.dart';
import '../services/community_safety_service.dart';

class CommunitySafetyScreen extends StatefulWidget {
  const CommunitySafetyScreen({super.key});

  @override
  State<CommunitySafetyScreen> createState() => _CommunitySafetyScreenState();
}

class _CommunitySafetyScreenState extends State<CommunitySafetyScreen> {
  final CommunitySafetyService _safetyService = CommunitySafetyService();
  double _trustIndex = 87.0;
  Map<String, int> _trustDistribution = {};
  List<int> _reportVolume = [];
  Map<String, int> _topCategories = {};
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final trustIndex = await _safetyService.calculateTrustIndex();
    final trustDistribution = await _safetyService.getTrustScoreDistribution();
    final reportVolume = await _safetyService.getReportVolume();
    final topCategories = await _safetyService.getTopCategories();
    final alerts = await _safetyService.getSafetyAlerts();

    setState(() {
      _trustIndex = trustIndex;
      _trustDistribution = trustDistribution;
      _reportVolume = reportVolume;
      _topCategories = topCategories;
      _alerts = alerts;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Community Safety',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Community Safety',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              'Last 30 Days',
              style: TextStyle(
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trust Index Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 92,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryTeal.withOpacity(0.12),
                          AppColors.primaryLight,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Safety overview',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                  color: AppColors.primaryTeal,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Healthy community signals',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 68,
                          height: 68,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.asset(
                              'assets/images/safety_hero.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TRUST INDEX',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getTrustLabel(_trustIndex),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'VERIFIED / FLAGS',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_trustDistribution['excellent'] ?? 0} / ${_alerts.length}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Trust Score Circle
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            value: _trustIndex / 100,
                            strokeWidth: 12,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getTrustColor(_trustIndex),
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            '${_trustIndex.toInt()}%',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: _getTrustColor(_trustIndex),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Trust Score Distribution
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trust Score Distribution',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if ((_trustDistribution['total'] ?? 0) == 0)
                    const Text(
                      'No trust data available yet.',
                      style: TextStyle(color: Colors.grey),
                    )
                  else ...[
                    _buildDistributionBar(
                      'Excellent (${_percentage('excellent')})',
                      _distributionValue('excellent'),
                      Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildDistributionBar(
                      'Good (${_percentage('good')})',
                      _distributionValue('good'),
                      Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _buildDistributionBar(
                      'Fair (${_percentage('fair')})',
                      _distributionValue('fair'),
                      Colors.amber,
                    ),
                    const SizedBox(height: 12),
                    _buildDistributionBar(
                      'Poor (${_percentage('poor')})',
                      _distributionValue('poor'),
                      Colors.red,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Report Volume & Top Categories
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Report Volume',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_reportVolume.isEmpty)
                          const Text(
                            'No report volume data yet.',
                            style: TextStyle(color: Colors.grey),
                          )
                        else ...[
                          SizedBox(
                            height: 100,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: _reportVolume.asMap().entries.map((entry) {
                                final index = entry.key;
                                final value = entry.value;
                                final maxValue = _reportVolume.reduce((a, b) => a > b ? a : b);
                                final height = maxValue == 0 ? 0.0 : (value / maxValue) * 100;
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      left: index == 0 ? 0 : 4,
                                      right: index == _reportVolume.length - 1 ? 0 : 4,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          height: height.clamp(8.0, 100.0),
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryTeal.withOpacity(0.75),
                                            borderRadius: const BorderRadius.vertical(
                                              top: Radius.circular(6),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${7 - (_reportVolume.length - index - 1)}d',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Top Categories',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_topCategories.isEmpty)
                          const Text(
                            'No categories reported yet.',
                            style: TextStyle(color: Colors.grey),
                          )
                        else ...[
                          ..._topCategories.entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildCategoryItem(entry.key, '${entry.value}'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Safety Alerts
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Safety Alerts',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_alerts.isEmpty)
                    const Text(
                      'No active safety alerts.',
                      style: TextStyle(color: Colors.grey),
                    )
                  else ...[
                    ..._alerts.map((alert) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildAlertItem(
                            alert['title'] as String? ?? 'Safety alert',
                            alert['description'] as String? ?? '',
                            (alert['type'] == 'critical') ? Colors.red : Colors.orange,
                            (alert['type'] == 'critical') ? 'CRITICAL' : 'ACTIVE',
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _distributionValue(String key) {
    final total = (_trustDistribution['total'] ?? 0);
    if (total == 0) return 0;
    final count = (_trustDistribution[key] ?? 0);
    return count / total;
  }

  String _percentage(String key) {
    final total = (_trustDistribution['total'] ?? 0);
    if (total == 0) return '0%';
    final count = (_trustDistribution[key] ?? 0);
    final percent = ((count / total) * 100).round();
    return '$percent%';
  }

  Widget _buildDistributionBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label.split('(')[0],
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              label.split('(')[1].replaceAll(')', ''),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(String label, String percentage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
        Text(
          percentage,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertItem(String title, String description, Color color, String badge) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.warning_amber,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTrustLabel(double trustIndex) {
    if (trustIndex >= 90) return 'Excellent';
    if (trustIndex >= 75) return 'Good';
    if (trustIndex >= 50) return 'Fair';
    return 'Poor';
  }

  Color _getTrustColor(double trustIndex) {
    if (trustIndex >= 90) return AppColors.primaryTeal;
    if (trustIndex >= 75) return Colors.green;
    if (trustIndex >= 50) return Colors.orange;
    return Colors.red;
  }
}
