import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:file_selector/file_selector.dart';
import '../../core/providers.dart';
import '../../core/security_provider.dart';
import '../updater/providers/update_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isLockEnabled = ref.watch(lockEnabledProvider);
    final isHideCodesEnabled = ref.watch(hideCodesProvider);
    final sortOrder = ref.watch(sortOrderProvider);

    final accountsAsync = ref.watch(watchAccountsProvider);
    final accounts = accountsAsync.value ?? [];
    
    final int totalAccounts = accounts.length;
    final int pinnedAccounts = accounts.where((a) => a.isPinned).length;
    final int hiddenAccounts = isHideCodesEnabled ? totalAccounts : 0; // Simple approximation

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Security
          _buildSectionHeader(context, 'Security', Icons.security),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint),
                  title: const Text('App Lock'),
                  subtitle: const Text('Require authentication to open'),
                  value: isLockEnabled,
                  onChanged: (val) {
                    ref.read(securityProvider.notifier).toggleLock(val);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.visibility_off),
                  title: const Text('Hide codes by default'),
                  subtitle: const Text('Tap card to reveal code'),
                  value: isHideCodesEnabled,
                  onChanged: (val) {
                    ref.read(hideCodesProvider.notifier).toggle(val);
                  },
                ),
              ],
            ),
          ),

          // Backup & Restore
          _buildSectionHeader(context, 'Backup & Restore', Icons.save_outlined),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Export Accounts (QR)'),
                  subtitle: const Text('Export as QR codes'),
                  leading: const Icon(Icons.qr_code_scanner),
                  onTap: () => _exportAccountsQR(context, ref, accounts),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Backup Database'),
                  subtitle: const Text('Export safekey.sqlite file'),
                  leading: const Icon(Icons.save_alt),
                  onTap: () => _exportDatabase(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Restore Database'),
                  subtitle: const Text('Import safekey.sqlite file'),
                  leading: const Icon(Icons.file_upload),
                  onTap: () => _importFromFile(context, ref),
                ),
              ],
            ),
          ),

          // Updates
          _buildSectionHeader(context, 'Updates', Icons.system_update),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.system_update),
                  title: const Text('Updates'),
                  subtitle: const Text('Check for new versions'),
                  onTap: () {
                    context.push('/updates');
                  },
                ),
              ],
            ),
          ),

          // Appearance
          _buildSectionHeader(context, 'Appearance', Icons.palette_outlined),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_6),
                  title: const Text('Theme'),
                  trailing: DropdownButton<ThemeMode>(
                    value: themeMode,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                      DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                      DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                    ],
                    onChanged: (mode) {
                      if (mode != null) {
                        ref.read(themeProvider.notifier).setTheme(mode);
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.sort),
                  title: const Text('Sort Order'),
                  trailing: DropdownButton<String>(
                    value: sortOrder,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'custom', child: Text('Custom (Drag)')),
                      DropdownMenuItem(value: 'recent', child: Text('Recent')),
                      DropdownMenuItem(value: 'name', child: Text('A-Z')),
                      DropdownMenuItem(value: 'issuer', child: Text('Issuer')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(sortOrderProvider.notifier).setSortOrder(val);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Statistics Dashboard
          _buildSectionHeader(context, 'Dashboard', Icons.analytics_outlined),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(context, 'Total', totalAccounts.toString(), Icons.format_list_numbered),
                  _buildStatItem(context, 'Pinned', pinnedAccounts.toString(), Icons.push_pin),
                  _buildStatItem(context, 'Hidden', hiddenAccounts.toString(), Icons.visibility_off),
                ],
              ),
            ),
          ),
          
          // About
          _buildSectionHeader(context, 'About', Icons.info_outline),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('SafeKey Version'),
                  trailing: Text(ref.watch(updateStateProvider).currentVersion.isNotEmpty ? ref.watch(updateStateProvider).currentVersion : '...', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.article),
                  title: const Text('Licensing'),
                  subtitle: const Text('View open-source licenses'),
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName: 'SafeKey',
                      applicationVersion: ref.read(updateStateProvider).currentVersion,
                    );
                  },
                ),
              ],
            ),
          ),
        ].animate(interval: 50.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuart),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 8.0, top: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title, 
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            )
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
      ],
    );
  }

  Future<bool> _confirmAndAuthenticate(BuildContext context, WidgetRef ref, String actionName, String warningText) async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error, size: 32),
                  const SizedBox(width: 16),
                  Expanded(child: Text('Security Warning', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                warningText,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                    icon: const Icon(Icons.security),
                    label: Text(actionName),
                    onPressed: () => Navigator.pop(ctx, true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return false;

    return await ref.read(securityProvider.notifier).authenticateForAction('Authenticate to $actionName');
  }

  Future<void> _exportAccountsQR(BuildContext context, WidgetRef ref, List<dynamic> accounts) async {
    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No accounts to export.')));
      return;
    }
    
    final authSuccess = await _confirmAndAuthenticate(
      context, ref, 'Export QR Codes',
      'This export contains unencrypted secrets for your accounts. Store it securely. Anyone with these QR codes may gain access to your accounts.'
    );
    
    if (authSuccess && context.mounted) {
      context.push('/export', extra: accounts);
    }
  }

  Future<void> _exportDatabase(BuildContext context, WidgetRef ref) async {
    final authSuccess = await _confirmAndAuthenticate(
      context, ref, 'Backup Database',
      'This backup contains encrypted secrets for your accounts. Store it securely. Anyone with this backup may gain access to your accounts.'
    );
    
    if (!authSuccess) return;

    if (!context.mounted) return;
    
    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: const [
            CircularProgressIndicator(),
            SizedBox(width: 24),
            Text('Generating backup...'),
          ],
        ),
      ),
    );

    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbPath = p.join(dbFolder.path, 'safekey.sqlite');
      final dbFile = File(dbPath);
      
      if (!await dbFile.exists()) {
        if (context.mounted) {
          Navigator.pop(context); // Close dialog
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No database found to export.')));
        }
        return;
      }
      
      final String fileName = 'safekey_backup_${DateTime.now().millisecondsSinceEpoch}.sqlite';
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(p.join(tempDir.path, fileName));
      await dbFile.copy(tempFile.path);
      
      if (context.mounted) Navigator.pop(context); // Close dialog
      
      final XFile xFile = XFile(tempFile.path);
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: 'SafeKey Database Backup',
        ),
      );
      
      if (context.mounted && result.status == ShareResultStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Database exported successfully')));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _importFromFile(BuildContext context, WidgetRef ref) async {
    final authSuccess = await _confirmAndAuthenticate(
      context, ref, 'Restore Database',
      'Restoring a database will permanently overwrite your current accounts. Ensure you are restoring a trusted SafeKey backup.'
    );
    
    if (!authSuccess) return;

    try {
      const typeGroup = XTypeGroup(label: 'SQLite', extensions: ['sqlite', 'db']);
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      
      if (file != null) {
        final dbFolder = await getApplicationDocumentsDirectory();
        final dbPath = p.join(dbFolder.path, 'safekey.sqlite');
        final walPath = p.join(dbFolder.path, 'safekey.sqlite-wal');
        final shmPath = p.join(dbFolder.path, 'safekey.sqlite-shm');
        final journalPath = p.join(dbFolder.path, 'safekey.sqlite-journal');
        
        // Delete temporary SQLite files to avoid restoring deleted accounts
        if (await File(walPath).exists()) await File(walPath).delete();
        if (await File(shmPath).exists()) await File(shmPath).delete();
        if (await File(journalPath).exists()) await File(journalPath).delete();
        
        // Overwrite main db file
        await File(file.path).copy(dbPath);
        
        ref.invalidate(databaseProvider);
        // also invalidate the account repo provider and accounts watch provider
        ref.invalidate(accountRepositoryProvider);
        ref.invalidate(watchAccountsProvider);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Database imported successfully.')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }
}
