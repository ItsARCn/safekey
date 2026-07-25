import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/update_provider.dart';
import '../widgets/markdown_viewer.dart';
import '../../settings/settings_screen.dart'; // Just to get some common styles if needed

class UpdatesScreen extends ConsumerWidget {
  const UpdatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateStateProvider);
    final notifier = ref.read(updateStateProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Updates'),
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.checkForUpdates(),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Status Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildStatusIcon(state.status, colorScheme),
                    const SizedBox(height: 16),
                    Text(
                      _getStatusText(state.status),
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Current Version: ${state.currentVersion}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    if (state.latestRelease != null && state.latestRelease!.version != state.currentVersion)
                      Text(
                        'Latest Version: ${state.latestRelease!.version}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    
                    if (state.errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          state.errorMessage,
                          style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    const SizedBox(height: 24),
                    _buildActionButtons(state, notifier, context),
                  ],
                ),
              ),
            ),
            
            // Download Progress (if downloading)
            if (state.status == UpdateStateStatus.downloading || state.status == UpdateStateStatus.paused) ...[
              const SizedBox(height: 24),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            state.status == UpdateStateStatus.paused ? 'Paused' : 'Downloading...',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text('${(state.downloadProgress * 100).toStringAsFixed(1)}%'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: state.downloadProgress > 0 ? state.downloadProgress : null,
                        borderRadius: BorderRadius.circular(8),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${state.downloadSpeed.toStringAsFixed(2)} MB/s',
                            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          if (state.timeRemaining.isNotEmpty)
                            Text(
                              '${state.timeRemaining} left',
                              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Changelog
            if (state.latestRelease != null) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                child: Text(
                  'Release Notes',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (state.latestRelease!.apkAsset != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
                  child: Text(
                    'Size: ${state.latestRelease!.apkAsset!.sizeInMB.toStringAsFixed(2)} MB • Released: ${DateFormat.yMMMd().format(state.latestRelease!.publishedAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: MarkdownViewer(markdownData: state.latestRelease!.body),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(UpdateStateStatus status, ColorScheme colorScheme) {
    IconData iconData;
    Color iconColor;

    switch (status) {
      case UpdateStateStatus.checking:
        return const CircularProgressIndicator();
      case UpdateStateStatus.upToDate:
        iconData = Icons.check_circle_outline;
        iconColor = Colors.green;
        break;
      case UpdateStateStatus.updateAvailable:
        iconData = Icons.system_update;
        iconColor = colorScheme.primary;
        break;
      case UpdateStateStatus.downloading:
        iconData = Icons.cloud_download_outlined;
        iconColor = colorScheme.primary;
        break;
      case UpdateStateStatus.paused:
        iconData = Icons.pause_circle_outline;
        iconColor = colorScheme.secondary;
        break;
      case UpdateStateStatus.downloaded:
        iconData = Icons.download_done;
        iconColor = Colors.green;
        break;
      case UpdateStateStatus.installing:
        iconData = Icons.build_circle_outlined;
        iconColor = colorScheme.primary;
        break;
      case UpdateStateStatus.error:
        iconData = Icons.error_outline;
        iconColor = colorScheme.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, size: 48, color: iconColor),
    );
  }

  String _getStatusText(UpdateStateStatus status) {
    switch (status) {
      case UpdateStateStatus.checking: return 'Checking for updates...';
      case UpdateStateStatus.upToDate: return 'SafeKey is up to date';
      case UpdateStateStatus.updateAvailable: return 'New Update Available';
      case UpdateStateStatus.downloading: return 'Downloading Update...';
      case UpdateStateStatus.paused: return 'Download Paused';
      case UpdateStateStatus.downloaded: return 'Ready to Install';
      case UpdateStateStatus.installing: return 'Launching Installer...';
      case UpdateStateStatus.error: return 'Update Failed';
    }
  }

  Widget _buildActionButtons(UpdateState state, UpdateNotifier notifier, BuildContext context) {
    switch (state.status) {
      case UpdateStateStatus.checking:
        return const SizedBox.shrink();
      
      case UpdateStateStatus.upToDate:
      case UpdateStateStatus.error:
        return FilledButton.tonalIcon(
          onPressed: () => notifier.checkForUpdates(),
          icon: const Icon(Icons.refresh),
          label: const Text('Check for Updates'),
        );
      
      case UpdateStateStatus.updateAvailable:
        return FilledButton.icon(
          onPressed: () => notifier.downloadUpdate(),
          icon: const Icon(Icons.download),
          label: const Text('Download Update'),
        );
      
      case UpdateStateStatus.downloading:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton.tonal(
              onPressed: () => notifier.pauseDownload(),
              child: const Text('Pause'),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: () => notifier.cancelDownload(),
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      
      case UpdateStateStatus.paused:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: () => notifier.resumeDownload(),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Resume'),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: () => notifier.cancelDownload(),
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      
      case UpdateStateStatus.downloaded:
        return FilledButton.icon(
          onPressed: () => notifier.installUpdate(),
          icon: const Icon(Icons.install_mobile),
          label: const Text('Install Update'),
        );
      
      case UpdateStateStatus.installing:
        return const CircularProgressIndicator();
    }
  }
}
