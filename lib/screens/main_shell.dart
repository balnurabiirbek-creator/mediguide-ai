import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/app_localizations.dart';
import '../services/providers.dart';
import '../utils/app_constants.dart';
import 'home_screen.dart';
import 'medicine_screen.dart';
import 'nearby_hospitals_screen.dart';
import 'profile_screen.dart';
import 'profile_setup_screen.dart';
import 'symptom_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    this.initialIndex = 0,
    this.showProfileSetup = false,
  });

  final int initialIndex;
  final bool showProfileSetup;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _pageController;
  late Animation<double> _pageAnim;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4);
    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _pageAnim = CurvedAnimation(
      parent: _pageController,
      curve: Curves.easeOut,
    );
    _pageController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    _pageController.reverse().then((_) {
      if (!mounted) return;
      setState(() => _currentIndex = index);
      _pageController.forward();
    });
  }

  Widget _buildScreen(int index) {
    final requiresProfileSetup = widget.showProfileSetup &&
        !context.watch<UserProvider>().profileCompleted;

    switch (index) {
      case 0:
        return HomeScreen(onNavigate: _onNavTap);
      case 1:
        return const SymptomCheckerScreen();
      case 2:
        return const MedicineScreen();
      case 3:
        return const NearbyHospitalsScreen();
      case 4:
        return requiresProfileSetup
            ? const ProfileSetupScreen(embeddedInShell: true)
            : const ProfileScreen();
      default:
        return HomeScreen(onNavigate: _onNavTap);
    }
  }

  @override
  Widget build(BuildContext context) {
    final navItems = [
      NavItem(
        icon: Icons.home_rounded,
        activeIcon: Icons.home_rounded,
        label: context.tr('home'),
      ),
      NavItem(
        icon: Icons.biotech_outlined,
        activeIcon: Icons.biotech_rounded,
        label: context.tr('symptoms'),
      ),
      NavItem(
        icon: Icons.medication_outlined,
        activeIcon: Icons.medication_rounded,
        label: context.tr('medicines'),
      ),
      NavItem(
        icon: Icons.location_on_outlined,
        activeIcon: Icons.location_on_rounded,
        label: context.tr('nearby'),
      ),
      NavItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: context.tr('profile'),
      ),
    ];

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: FadeTransition(
              opacity: _pageAnim,
              child: _buildScreen(_currentIndex),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(navItems),
    );
  }

  Widget _buildBottomNav(List<NavItem> navItems) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingS,
            vertical: AppDimensions.paddingS,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == _currentIndex;

              return _NavBarItem(
                item: item,
                isSelected: isSelected,
                onTap: () => _onNavTap(index),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _NavBarItem extends StatefulWidget {
  final NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.85,
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
        widget.onTap();
      },
      onTapCancel: () => _controller.forward(),
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: widget.isSelected
              ? BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  widget.isSelected ? widget.item.activeIcon : widget.item.icon,
                  key: ValueKey(widget.isSelected),
                  color: widget.isSelected
                      ? AppColors.primary
                      : AppColors.textHint,
                  size: AppDimensions.iconL,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: AppTextStyles.caption.copyWith(
                  color: widget.isSelected
                      ? AppColors.primary
                      : AppColors.textHint,
                  fontWeight:
                      widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                child: Text(widget.item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
