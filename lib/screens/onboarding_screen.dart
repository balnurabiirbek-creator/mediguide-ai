import 'package:flutter/material.dart';
import '../services/app_localizations.dart';
import '../utils/app_constants.dart';

class OnboardingScreen extends StatefulWidget {
  final Future<void> Function() onFinish;
  final bool returnToRootOnFinish;

  const OnboardingScreen({
    super.key,
    required this.onFinish,
    this.returnToRootOnFinish = true,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    await widget.onFinish();
    if (!mounted) return;
    if (widget.returnToRootOnFinish) {
      Navigator.of(context).pushReplacementNamed('/');
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      OnboardingData(
        emoji: '🩺',
        title: context.tr('onboardingTitle1'),
        subtitle: context.tr('onboardingSubtitle1'),
        gradient: const [Color(0xFF4A90E2), Color(0xFF5B9FEF)],
        features: const [],
      ),
      OnboardingData(
        emoji: '🔬',
        title: context.tr('onboardingTitle2'),
        subtitle: context.tr('onboardingSubtitle2'),
        gradient: const [Color(0xFF7B5EA7), Color(0xFF9B7EC8)],
        features: [
          context.tr('onboardingFeatureAnalysis'),
          context.tr('onboardingFeatureSeverity'),
          context.tr('onboardingFeatureGuidance'),
        ],
      ),
      OnboardingData(
        emoji: '💊',
        title: context.tr('onboardingTitle3'),
        subtitle: context.tr('onboardingSubtitle3'),
        gradient: const [Color(0xFF22C55E), Color(0xFF4ADE80)],
        features: [
          context.tr('onboardingFeatureSafety'),
          context.tr('onboardingFeatureWarnings'),
          context.tr('onboardingFeatureDosing'),
        ],
      ),
      OnboardingData(
        emoji: '🗺️',
        title: context.tr('onboardingTitle4'),
        subtitle: context.tr('onboardingSubtitle4'),
        gradient: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
        features: [
          context.tr('onboardingFeatureClinics'),
          context.tr('onboardingFeaturePharmacies'),
          context.tr('onboardingFeatureContacts'),
        ],
      ),
    ];

    final currentPageData = pages[_currentPage];

    return Scaffold(
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: currentPageData.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingL,
                    vertical: AppDimensions.paddingS,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '💊',
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context.tr('appName'),
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      if (_currentPage < pages.length - 1)
                        TextButton(
                          onPressed: _finishOnboarding,
                          child: Text(
                            context.tr('skip'),
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: pages.length,
                    itemBuilder: (context, index) {
                      return _OnboardingPage(data: pages[index]);
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(pages.length, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: index == _currentPage ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: index == _currentPage
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        width: double.infinity,
                        height: AppDimensions.buttonHeight,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusXL,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: _nextPage,
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusXL,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentPage == pages.length - 1
                                    ? context.tr('getStarted')
                                    : context.tr('next'),
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  color: currentPageData.gradient.first,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _currentPage == pages.length - 1
                                    ? Icons.rocket_launch_rounded
                                    : Icons.arrow_forward_rounded,
                                color: currentPageData.gradient.first,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.paddingS),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                data.emoji,
                style: const TextStyle(fontSize: 72),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.6,
            ),
          ),
          if (data.features.isNotEmpty) ...[
            const SizedBox(height: 24),
            ...data.features.map(
              (feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  feature,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class OnboardingData {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final List<String> features;

  const OnboardingData({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.features,
  });
}
