import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_localizations.dart';
import '../services/providers.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import '../widgets/common_widgets.dart';

class HealthTrackerScreen extends StatelessWidget {
  const HealthTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final activities = userProvider.recentActivity;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.dynamicText('Health Tracker')),
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GradientCard(
              colors: const [AppTheme.brandBlue, Color(0xFF22C55E)],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.monitor_heart_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.dynamicText('Your health snapshot'),
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              context.dynamicText(
                                'Track recent checks, personal indicators, and follow-up actions in one place.',
                              ),
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _TrackerMetricCard(
                    icon: Icons.history_rounded,
                    label: context.dynamicText('Recent checks'),
                    value: '${activities.length}',
                    accent: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TrackerMetricCard(
                    icon: Icons.warning_amber_rounded,
                    label: context.tr('allergies'),
                    value: '${userProvider.allergies.length}',
                    accent: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TrackerMetricCard(
                    icon: Icons.assignment_rounded,
                    label: context.tr('conditions'),
                    value: '${userProvider.conditions.length}',
                    accent: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TrackerMetricCard(
                    icon: Icons.bookmark_rounded,
                    label: context.tr('savedPlaces'),
                    value: '${userProvider.savedPlaces.length}',
                    accent: AppTheme.brandCoral,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.dynamicText('Health summary'),
                    style: AppTextStyles.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryTile(
                          label: context.tr('bloodType'),
                          value: userProvider.bloodType.isEmpty
                              ? context.tr('notSet')
                              : userProvider.bloodType,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryTile(
                          label: context.tr('weightKg'),
                          value: userProvider.weight > 0
                              ? '${userProvider.weight.toStringAsFixed(0)} kg'
                              : '--',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryTile(
                          label: context.tr('heightCm'),
                          value: userProvider.height > 0
                              ? '${userProvider.height.toStringAsFixed(0)} cm'
                              : '--',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.dynamicText('Suggested next steps'),
                    style: AppTextStyles.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  _TrackerAdviceRow(
                    icon: Icons.biotech_rounded,
                    title: context.dynamicText('Run an AI symptom check'),
                    subtitle: context.dynamicText(
                      'Use the symptom checker when you feel something unusual.',
                    ),
                    accent: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  _TrackerAdviceRow(
                    icon: Icons.local_hospital_rounded,
                    title: context.dynamicText('Keep one hospital saved'),
                    subtitle: context.dynamicText(
                      'Save a nearby clinic or hospital for faster access in urgent situations.',
                    ),
                    accent: AppColors.success,
                  ),
                  const SizedBox(height: 12),
                  _TrackerAdviceRow(
                    icon: Icons.medication_rounded,
                    title: context.dynamicText('Review medicine warnings'),
                    subtitle: context.dynamicText(
                      'Check allergy notes before taking a new medicine.',
                    ),
                    accent: AppColors.warning,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.dynamicText('Timeline'),
                    style: AppTextStyles.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  if (activities.isEmpty)
                    EmptyState(
                      emoji: '📈',
                      title: context.dynamicText('No tracker history yet'),
                      subtitle: context.dynamicText(
                        'Start checking symptoms, medicines, or nearby hospitals to build your health timeline.',
                      ),
                    )
                  else
                    Column(
                      children: activities.asMap().entries.map((entry) {
                        final item = entry.value;
                        return _TimelineTile(
                          icon: item['icon'] as String? ?? '📋',
                          title: context.dynamicText(
                            item['title'] as String? ?? 'Activity',
                          ),
                          subtitle: context.dynamicText(
                            item['subtitle'] as String? ?? '',
                          ),
                          timeLabel: _formatTime(
                            context,
                            item['createdAt'] ?? item['timestamp'],
                          ),
                          isLast: entry.key == activities.length - 1,
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(BuildContext context, dynamic rawValue) {
    DateTime? dt;
    if (rawValue is DateTime) {
      dt = rawValue;
    } else if (rawValue is String) {
      dt = DateTime.tryParse(rawValue);
    }

    if (dt == null) return context.tr('now');
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return context.tr('now');
    if (diff.inHours < 1) {
      return context.tr('minutesAgo', params: {'count': '${diff.inMinutes}'});
    }
    if (diff.inDays < 1) {
      return context.tr('hoursAgo', params: {'count': '${diff.inHours}'});
    }
    return context.tr('daysAgo', params: {'count': '${diff.inDays}'});
  }
}

class _TrackerMetricCard extends StatelessWidget {
  const _TrackerMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.headlineLarge.copyWith(color: accent),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackerAdviceRow extends StatelessWidget {
  const _TrackerAdviceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.headlineSmall),
              const SizedBox(height: 4),
              Text(subtitle, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.isLast,
  });

  final String icon;
  final String title;
  final String subtitle;
  final String timeLabel;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 20)),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 46,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: AppColors.divider,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title, style: AppTextStyles.headlineSmall),
                    ),
                    const SizedBox(width: 8),
                    Text(timeLabel, style: AppTextStyles.caption),
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
