import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../theme/app_tokens.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<({String title, String subtitle, String highlight, IconData icon})> _pages = const [
    (
      title: 'Welcome to SafeKey',
      subtitle: 'Your modern, open-source authenticator built with Google Material 3 and uncompromising security.',
      highlight: 'SECURE AUTHENTICATION',
      icon: Icons.shield_rounded,
    ),
    (
      title: 'Completely Offline',
      subtitle: 'Zero trackers, zero cloud leaks. Your two-factor tokens and secrets never leave your device.',
      highlight: 'AIR-GAPPED PRIVACY',
      icon: Icons.wifi_off_rounded,
    ),
    (
      title: 'AES-256 SQLCipher',
      subtitle: 'Industry-standard cryptographic hardware encryption safeguards your accounts at rest.',
      highlight: 'HARDWARE-BACKED VAULT',
      icon: Icons.lock_clock_rounded,
    ),
  ];

  Future<void> _completeOnboarding() async {
    HapticFeedback.mediumImpact();
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('first_launch', false);
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.space20, vertical: AppTokens.space12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // App Emblem
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTokens.space6),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                        ),
                        child: Icon(Icons.security, size: 18, color: colorScheme.primary),
                      ),
                      const SizedBox(width: AppTokens.space8),
                      Text(
                        'SafeKey',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),

                  // Skip Button
                  AnimatedOpacity(
                    opacity: isLastPage ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: TextButton(
                      onPressed: isLastPage
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                              _pageController.animateToPage(
                                _pages.length - 1,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOutCubic,
                              );
                            },
                      child: const Text('Skip'),
                    ),
                  ),
                ],
              ),
            ),

            // Page View Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  HapticFeedback.selectionClick();
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTokens.space32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Expressive Hero Emblem
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                          ),
                          child: Center(
                            child: Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    colorScheme.primary,
                                    colorScheme.secondary,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  page.icon,
                                  size: AppTokens.iconSizeHero * 0.65,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        )
                            .animate(key: ValueKey('icon_$index'))
                            .scale(duration: 500.ms, curve: Curves.easeOutBack)
                            .fadeIn(duration: 350.ms),

                        const SizedBox(height: AppTokens.space40),

                        // Pill Highlight Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppTokens.space12, vertical: AppTokens.space4),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                          ),
                          child: Text(
                            page.highlight,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        )
                            .animate(key: ValueKey('tag_$index'))
                            .fadeIn(duration: 300.ms)
                            .slideY(begin: 0.2, end: 0),

                        const SizedBox(height: AppTokens.space16),

                        // Title
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                            color: colorScheme.onSurface,
                          ),
                        )
                            .animate(key: ValueKey('title_$index'))
                            .fadeIn(delay: 100.ms, duration: 400.ms)
                            .slideY(begin: 0.15, end: 0),

                        const SizedBox(height: AppTokens.space16),

                        // Subtitle
                        Text(
                          page.subtitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.55,
                          ),
                        )
                            .animate(key: ValueKey('subtitle_$index'))
                            .fadeIn(delay: 200.ms, duration: 400.ms)
                            .slideY(begin: 0.15, end: 0),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation & Morphing Indicators
            Padding(
              padding: const EdgeInsets.all(AppTokens.space24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Animated Morphing Page Indicator
                  Row(
                    children: List.generate(_pages.length, (index) {
                      final isSelected = _currentPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
                        height: 8,
                        width: isSelected ? 28 : 8,
                        decoration: BoxDecoration(
                          color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                        ),
                      );
                    }),
                  ),

                  // Next / Get Started Action Button
                  FilledButton.icon(
                    onPressed: () {
                      if (!isLastPage) {
                        HapticFeedback.lightImpact();
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                        );
                      } else {
                        _completeOnboarding();
                      }
                    },
                    icon: Icon(
                      isLastPage ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                      size: 20,
                    ),
                    label: Text(
                      isLastPage ? 'Get Started' : 'Next',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space24, vertical: AppTokens.space16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

