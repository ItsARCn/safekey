import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/providers.dart';
import 'core/router.dart';
import 'core/security_provider.dart';
import 'theme/app_theme.dart';
import 'theme/app_tokens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const SafeKeyApp(),
    ),
  );
}

class SafeKeyApp extends ConsumerStatefulWidget {
  const SafeKeyApp({super.key});

  @override
  ConsumerState<SafeKeyApp> createState() => _SafeKeyAppState();
}

class _SafeKeyAppState extends ConsumerState<SafeKeyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(securityProvider)) {
        ref.read(securityProvider.notifier).authenticate();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      ref.read(securityProvider.notifier).lock();
    } else if (state == AppLifecycleState.resumed) {
      final isLocked = ref.read(securityProvider);
      if (isLocked) {
        ref.read(securityProvider.notifier).authenticate();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(securityProvider);
    final themeMode = ref.watch(themeProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp.router(
          title: 'SafeKey',
          theme: AppTheme.buildTheme(lightDynamic, isDark: false),
          darkTheme: AppTheme.buildTheme(darkDynamic, isDark: true),
          themeMode: themeMode,
          routerConfig: goRouter,
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;

            return Stack(
              children: [
                ?child,
                if (isLocked)
                  Material(
                    color: colorScheme.surface,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppTokens.space24),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_rounded,
                              size: AppTokens.iconSizeHero,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: AppTokens.space24),
                          Text(
                            'SafeKey Locked',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: AppTokens.space8),
                          Text(
                            'Biometric authentication required',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppTokens.space24),
                          FilledButton.icon(
                            onPressed: () {
                              ref.read(securityProvider.notifier).authenticate();
                            },
                            icon: const Icon(Icons.fingerprint_rounded),
                            label: const Text('Unlock'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTokens.space32,
                                vertical: AppTokens.space16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
