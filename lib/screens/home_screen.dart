import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'emergency_screen.dart';
import 'health_tracker_screen.dart';
import 'hospital_detail_screen.dart';
import 'settings_screen.dart';
import '../services/app_localizations.dart';
import '../utils/app_constants.dart';
import '../services/providers.dart';
import '../widgets/common_widgets.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _headerController;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  int _currentTipIndex = 0;
  final PageController _tipController = PageController();

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerFade = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: Curves.easeOutCubic,
      ),
    );
    _headerController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _tipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final auth = context.watch<AuthService>();
    final userName = userProvider.name.isNotEmpty && userProvider.name != 'User'
        ? userProvider.name
        : (auth.currentUser?.displayName ?? 'User');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeader(userName),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.paddingL,
                0,
                AppDimensions.paddingL,
                16,
              ),
              child: _buildDashboardStarter(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.paddingL,
                0,
                AppDimensions.paddingL,
                AppDimensions.paddingL,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: context.tr('quickActions')),
                  const SizedBox(height: 12),
                  _buildQuickActions(),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingL,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'MVP Pages'),
                  const SizedBox(height: 12),
                  _buildPageLaunchpad(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingL,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: context.tr('yourHealthStats')),
                  const SizedBox(height: 12),
                  _buildHealthStats(userProvider),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingL,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Nearby Preview'),
                  const SizedBox(height: 12),
                  _buildNearbyPreview(userProvider),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingL,
                  ),
                  child: SectionHeader(
                    title: context.tr('healthTips'),
                    action: context.tr('seeAll'),
                    onAction: () {},
                  ),
                ),
                const SizedBox(height: 12),
                _buildHealthTips(userProvider.healthTips),
                const SizedBox(height: 10),
                _buildTipsIndicator(userProvider.healthTips.length),
                const SizedBox(height: 24),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingL,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: context.tr('recentActivity')),
                  const SizedBox(height: 12),
                  _buildRecentActivity(userProvider.recentActivity),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPage(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Widget _buildHeader(String userName) {
    return FadeTransition(
      opacity: _headerFade,
      child: SlideTransition(
        position: _headerSlide,
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.greeting(),
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '$userName 👋',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            context.watch<UserProvider>().avatarEmoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '🚨',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('emergencyTitle'),
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                context.tr('emergencySubtitle'),
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
        emoji: '🔬',
        label: context.tr('symptomChecker'),
        color: AppColors.primary,
        onTap: () => widget.onNavigate(1),
      ),
      _QuickAction(
        emoji: '💊',
        label: context.tr('medicineGuide'),
        color: const Color(0xFF7B5EA7),
        onTap: () => widget.onNavigate(2),
      ),
      _QuickAction(
        emoji: '🗺️',
        label: context.tr('nearbyMedicalHelp'),
        color: const Color(0xFF22C55E),
        onTap: () => widget.onNavigate(3),
      ),
      _QuickAction(
        emoji: '🚑',
        label: 'Emergency\nCenter',
        color: AppColors.danger,
        onTap: () => _openPage(const EmergencyScreen()),
      ),
      _QuickAction(
        emoji: '📈',
        label: 'Health\nTracker',
        color: const Color(0xFF0EA5E9),
        onTap: () => _openPage(const HealthTrackerScreen()),
      ),
      _QuickAction(
        emoji: '👤',
        label: context.tr('profile'),
        color: const Color(0xFFF59E0B),
        onTap: () => widget.onNavigate(4),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: actions.asMap().entries.map((entry) {
            return SizedBox(
              width: itemWidth,
              child: AnimatedListItem(
                index: entry.key,
                child: _QuickActionCard(action: entry.value),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDashboardStarter() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Start from symptoms, medicine, or urgent care',
            style: AppTextStyles.headlineSmall,
          ),
          const SizedBox(height: 12),
          TextFormField(
            readOnly: true,
            onTap: () => widget.onNavigate(1),
            decoration: InputDecoration(
              hintText: 'Describe your symptom to start an AI check',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                onPressed: () => widget.onNavigate(1),
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => widget.onNavigate(1),
                  icon: const Icon(Icons.biotech_rounded),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Check Symptoms'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => widget.onNavigate(2),
                  icon: const Icon(Icons.medication_rounded),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Find Medicine'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageLaunchpad() {
    final items = [
      (
        'Emergency Center',
        'Fast ambulance access and urgent actions',
        Icons.emergency_rounded,
        AppColors.danger,
        const EmergencyScreen(),
      ),
      (
        'Health Tracker',
        'History, summaries, and health timeline',
        Icons.monitor_heart_rounded,
        const Color(0xFF0EA5E9),
        const HealthTrackerScreen(),
      ),
      (
        'Settings',
        'Language, theme, privacy, and preferences',
        Icons.settings_rounded,
        const Color(0xFF7B5EA7),
        const SettingsScreen(),
      ),
    ];

    return Column(
      children: items.asMap().entries.map((entry) {
        final item = entry.value;
        return AnimatedListItem(
          index: entry.key,
          child: Padding(
            padding:
                EdgeInsets.only(bottom: entry.key == items.length - 1 ? 0 : 12),
            child: AppCard(
              onTap: () => _openPage(item.$5),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: item.$4.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(item.$3, color: item.$4),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.$1, style: AppTextStyles.headlineSmall),
                        const SizedBox(height: 4),
                        Text(item.$2, style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNearbyPreview(UserProvider userProvider) {
    final places = userProvider.savedPlaces;

    if (places.isEmpty) {
      return GradientCard(
        child: Row(
          children: [
            const Icon(
              Icons.map_rounded,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Open nearby hospitals map',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('noSavedPlacesSubtitle'),
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: () => widget.onNavigate(3),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
              ),
              child: const Text('Open'),
            ),
          ],
        ),
      );
    }

    final place = places.first;
    return AppCard(
      onTap: () => _openPage(HospitalDetailScreen(place: place)),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.local_hospital_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(place.name, style: AppTextStyles.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  place.address,
                  style: AppTextStyles.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to open hospital detail page',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }

  Widget _buildHealthStats(UserProvider userProvider) {
    final stats = [
      {
        'label': 'Allergies',
        'localizedLabel': context.tr('allergies'),
        'value': '${userProvider.allergies.length}',
        'icon': '⚠️',
        'color': AppColors.warning,
      },
      {
        'label': 'Conditions',
        'localizedLabel': context.tr('conditions'),
        'value': '${userProvider.conditions.length}',
        'icon': '📋',
        'color': AppColors.primary,
      },
      {
        'label': 'Checkups',
        'localizedLabel': context.tr('checkups'),
        'value': '0',
        'icon': '🏥',
        'color': AppColors.success,
      },
    ];

    return Row(
      children: stats.asMap().entries.map((entry) {
        final stat = entry.value;
        return Expanded(
          child: AnimatedListItem(
            index: entry.key,
            child: Container(
              margin: EdgeInsets.only(right: entry.key < 2 ? 12 : 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    stat['icon'] as String,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    stat['value'] as String,
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: stat['color'] as Color,
                    ),
                  ),
                  Text(
                    (stat['localizedLabel'] ?? stat['label']) as String,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHealthTips(List<Map<String, dynamic>> tips) {
    return SizedBox(
      height: 160,
      child: PageView.builder(
        controller: _tipController,
        onPageChanged: (i) => setState(() => _currentTipIndex = i),
        itemCount: tips.length,
        itemBuilder: (context, index) {
          final tip = tips[index];
          final color = Color(int.parse(tip['color'] as String));

          return Container(
            margin: EdgeInsets.only(
              left: index == 0 ? AppDimensions.paddingL : 8,
              right: index == tips.length - 1 ? AppDimensions.paddingL : 8,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color,
                  color.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tip['icon'] as String,
                      style: const TextStyle(fontSize: 32),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        context.dynamicText(tip['category'] as String),
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  context.dynamicText(tip['title'] as String),
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.dynamicText(tip['content'] as String),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTipsIndicator(int count) {
    if (count <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentTipIndex == index ? 18 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentTipIndex == index
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(List<Map<String, dynamic>> activities) {
    if (activities.isEmpty) {
      return EmptyState(
        emoji: '📊',
        title: context.tr('noRecentActivity'),
        subtitle: context.tr('noRecentActivitySubtitle'),
      );
    }

    final userProvider = context.read<UserProvider>();

    return Column(
      children: activities.take(5).toList().asMap().entries.map((entry) {
        final activity = entry.value;
        final activityId = activity['id'] as String?;
        return AnimatedListItem(
          index: entry.key,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        activity['icon'] as String? ?? '📋',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.dynamicText(
                            activity['title'] as String? ?? 'Activity',
                          ),
                          style: AppTextStyles.headlineSmall,
                        ),
                        Text(
                          context.dynamicText(
                            activity['subtitle'] as String? ?? '',
                          ),
                          style: AppTextStyles.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(
                            activity['createdAt'] ?? activity['timestamp']),
                        style: AppTextStyles.caption,
                      ),
                      if (activityId != null && activityId.isNotEmpty)
                        IconButton(
                          tooltip: context.tr('removeActivity'),
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.textHint,
                          ),
                          constraints: const BoxConstraints.tightFor(
                            width: 28,
                            height: 28,
                          ),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          onPressed: () async {
                            await userProvider.removeRecentActivity(activityId);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(context.tr('activityRemoved')),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatTime(dynamic rawValue) {
    DateTime? dt;
    if (rawValue is DateTime) {
      dt = rawValue;
    } else if (rawValue is String) {
      dt = DateTime.tryParse(rawValue);
    }

    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
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

class _QuickAction {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _QuickAction({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _QuickActionCard extends StatefulWidget {
  final _QuickAction action;

  const _QuickActionCard({required this.action});

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
    )..value = 1.0;
    _scaleAnim = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) {
        _controller.forward();
        widget.action.onTap();
      },
      onTapCancel: () => _controller.forward(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: widget.action.color.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: widget.action.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    widget.action.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.action.label,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
