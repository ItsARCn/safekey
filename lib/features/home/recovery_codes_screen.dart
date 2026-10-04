import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../database/database.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/m3_card.dart';
import '../../widgets/m3_empty_state.dart';

class RecoveryCodesScreen extends ConsumerStatefulWidget {
  final Account account;

  const RecoveryCodesScreen({super.key, required this.account});

  @override
  ConsumerState<RecoveryCodesScreen> createState() => _RecoveryCodesScreenState();
}

class _RecoveryCodesScreenState extends ConsumerState<RecoveryCodesScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _addCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    final newCode = RecoveryCodesCompanion.insert(
      accountId: widget.account.id,
      code: code,
    );

    await ref.read(accountRepositoryProvider).insertRecoveryCode(newCode);
    _codeController.clear();
  }

  void _copyToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.lightImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recovery code copied to clipboard'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAddCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Recovery Code'),
        content: TextField(
          controller: _codeController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Recovery Code',
            hintText: 'e.g. ABCD-1234-EFGH',
            prefixIcon: Icon(Icons.key_rounded),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _addCode();
              Navigator.pop(context);
            },
            child: const Text('Add Code'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final repo = ref.watch(accountRepositoryProvider);
    final codesStream = repo.watchRecoveryCodesForAccount(widget.account.id);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.account.issuer} Recovery Codes'),
      ),
      body: Column(
        children: [
          // Informational Header Banner Card
          Padding(
            padding: const EdgeInsets.fromLTRB(AppTokens.space16, AppTokens.space8, AppTokens.space16, AppTokens.space8),
            child: Container(
              padding: const EdgeInsets.all(AppTokens.space16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTokens.space10),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.security_rounded, color: colorScheme.primary, size: 22),
                  ),
                  const SizedBox(width: AppTokens.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.account.accountName,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppTokens.space2),
                        Text(
                          'One-time emergency codes stored encrypted with AES-256.',
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Code List or Empty State
          Expanded(
            child: StreamBuilder<List<RecoveryCode>>(
              stream: codesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final codes = snapshot.data ?? [];
                if (codes.isEmpty) {
                  return M3EmptyState(
                    icon: Icons.shield_outlined,
                    title: 'No Recovery Codes',
                    description: 'Store backup one-time codes generated by ${widget.account.issuer} for emergency recovery.',
                    primaryActionIcon: Icons.add_rounded,
                    primaryActionLabel: 'Add First Code',
                    onPrimaryAction: _showAddCodeDialog,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(AppTokens.space16, AppTokens.space8, AppTokens.space16, 96),
                  itemCount: codes.length,
                  itemBuilder: (context, index) {
                    final code = codes[index];
                    return M3Card(
                      margin: const EdgeInsets.only(bottom: AppTokens.space10),
                      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space16, vertical: AppTokens.space12),
                      child: Row(
                        children: [
                          // Status Indicator Icon
                          Container(
                            padding: const EdgeInsets.all(AppTokens.space8),
                            decoration: BoxDecoration(
                              color: code.isUsed
                                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                                  : colorScheme.primaryContainer.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              code.isUsed ? Icons.check_circle_outline_rounded : Icons.key_rounded,
                              size: 18,
                              color: code.isUsed ? colorScheme.outline : colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: AppTokens.space16),

                          // Code String
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  code.code,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    decoration: code.isUsed ? TextDecoration.lineThrough : null,
                                    color: code.isUsed ? colorScheme.outline : colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: AppTokens.space2),
                                Text(
                                  code.isUsed ? 'Used' : 'Available',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: code.isUsed ? colorScheme.outline : colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Actions: Copy, Checkbox, Delete
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 20),
                            onPressed: code.isUsed ? null : () => _copyToClipboard(code.code),
                            tooltip: 'Copy Code',
                          ),
                          Checkbox(
                            value: code.isUsed,
                            onChanged: (val) {
                              if (val != null) {
                                HapticFeedback.selectionClick();
                                repo.updateRecoveryCode(code.copyWith(isUsed: val));
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded, size: 20, color: colorScheme.error),
                            tooltip: 'Delete Code',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Recovery Code?'),
                                  content: const Text('Are you sure you want to permanently delete this recovery code?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    FilledButton(
                                      style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                repo.deleteRecoveryCode(code);
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCodeDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Code', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

