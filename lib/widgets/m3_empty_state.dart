import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_tokens.dart';

/// Expressive Material 3 Empty State with layered tonal iconography,
/// hierarchy-focused typography, and primary/tonal action buttons.
class M3EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? primaryActionLabel;
  final IconData? primaryActionIcon;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final IconData? secondaryActionIcon;
  final VoidCallback? onSecondaryAction;

  const M3EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.primaryActionLabel,
    this.primaryActionIcon,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.secondaryActionIcon,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space32, vertical: AppTokens.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Layered Tonal Icon Badge
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: AppTokens.iconSizeExtraLarge,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack).fadeIn(duration: 300.ms),

            const SizedBox(height: AppTokens.space28),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: colorScheme.onSurface,
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.15, end: 0),

            const SizedBox(height: AppTokens.space12),

            // Description
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.15, end: 0),

            if (primaryActionLabel != null || secondaryActionLabel != null) ...[
              const SizedBox(height: AppTokens.space32),

              // Action Buttons
              if (primaryActionLabel != null)
                FilledButton.icon(
                  onPressed: onPrimaryAction,
                  icon: primaryActionIcon != null ? Icon(primaryActionIcon) : const SizedBox.shrink(),
                  label: Text(primaryActionLabel!),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: AppTokens.space28, vertical: AppTokens.space16),
                    minimumSize: const Size(200, 52),
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),

              if (secondaryActionLabel != null) ...[
                const SizedBox(height: AppTokens.space12),
                OutlinedButton.icon(
                  onPressed: onSecondaryAction,
                  icon: secondaryActionIcon != null ? Icon(secondaryActionIcon) : const SizedBox.shrink(),
                  label: Text(secondaryActionLabel!),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: AppTokens.space28, vertical: AppTokens.space16),
                    minimumSize: const Size(200, 52),
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
