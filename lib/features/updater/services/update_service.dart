import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../models/github_release.dart';
import 'github_service.dart';
import '../providers/update_provider.dart';

class UpdateService {
  final Ref ref;
  final GithubService _githubService = GithubService();
  late UpdateNotifier _notifier;
  String? _downloadedApkPath;

  UpdateService(this.ref);

  void init(UpdateNotifier notifier) {
    _notifier = notifier;
    
    FileDownloader().updates.listen((update) {
      if (update is TaskStatusUpdate) {
        if (update.status == TaskStatus.complete) {
          _notifier.updateState(_notifier.currentState.copyWith(
            status: UpdateStateStatus.downloaded,
            downloadProgress: 1.0,
          ));
          _notifyReadyToInstall();
        } else if (update.status == TaskStatus.paused) {
          _notifier.updateState(_notifier.currentState.copyWith(
            status: UpdateStateStatus.paused,
          ));
        } else if (update.status == TaskStatus.failed || update.status == TaskStatus.canceled) {
          _notifier.updateState(_notifier.currentState.copyWith(
            status: update.status == TaskStatus.canceled ? UpdateStateStatus.updateAvailable : UpdateStateStatus.error,
            errorMessage: update.status == TaskStatus.failed ? 'Download failed' : '',
            downloadProgress: 0.0,
          ));
        }
      } else if (update is TaskProgressUpdate) {
        _notifier.updateState(_notifier.currentState.copyWith(
          status: UpdateStateStatus.downloading,
          downloadProgress: update.progress,
          downloadSpeed: update.networkSpeed,
          timeRemaining: update.timeRemaining.inSeconds > 0 ? '${update.timeRemaining.inSeconds}s' : '',
        ));
      }
    });
  }

  Future<void> checkForUpdates({bool silent = false}) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionStr = packageInfo.version;
      _notifier.updateState(_notifier.currentState.copyWith(currentVersion: currentVersionStr));

      final release = await _githubService.getLatestRelease();
      if (release == null) {
        if (!silent) {
          _notifier.updateState(_notifier.currentState.copyWith(
            status: UpdateStateStatus.error,
            errorMessage: 'Failed to check for updates (Network error).',
          ));
        } else {
          _notifier.updateState(_notifier.currentState.copyWith(status: UpdateStateStatus.upToDate));
        }
        return;
      }

      final current = Version.parse(currentVersionStr);
      final latest = Version.parse(release.version);

      if (latest > current) {
        _notifier.updateState(_notifier.currentState.copyWith(
          status: UpdateStateStatus.updateAvailable,
          latestRelease: release,
        ));
      } else {
        _notifier.updateState(_notifier.currentState.copyWith(
          status: UpdateStateStatus.upToDate,
          latestRelease: release,
        ));
      }
    } catch (e) {
      if (!silent) {
        _notifier.updateState(_notifier.currentState.copyWith(
          status: UpdateStateStatus.error,
          errorMessage: 'Error parsing versions: $e',
        ));
      } else {
        _notifier.updateState(_notifier.currentState.copyWith(status: UpdateStateStatus.upToDate));
      }
    }
  }

  Future<void> downloadUpdate(GithubRelease release) async {
    final asset = release.apkAsset;
    if (asset == null) {
      _notifier.updateState(_notifier.currentState.copyWith(
        status: UpdateStateStatus.error,
        errorMessage: 'No APK found in the latest release.',
      ));
      return;
    }

    final status = await Permission.requestInstallPackages.request();
    if (!status.isGranted) {
      _notifier.updateState(_notifier.currentState.copyWith(
        status: UpdateStateStatus.error,
        errorMessage: 'Permission to install unknown apps is required.',
      ));
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final savePath = p.join(dir.path, asset.name);
    _downloadedApkPath = savePath;

    final task = DownloadTask(
      url: asset.downloadUrl,
      filename: asset.name,
      directory: 'updates',
      updates: Updates.statusAndProgress,
      allowPause: true,
      metaData: release.version,
    );

    _notifier.updateState(_notifier.currentState.copyWith(
      status: UpdateStateStatus.downloading,
      currentTask: task,
      downloadProgress: 0.0,
      downloadedMB: 0.0,
    ));

    await FileDownloader().enqueue(task);
  }

  Future<void> pauseDownload(DownloadTask task) async {
    await FileDownloader().pause(task);
  }

  Future<void> resumeDownload(DownloadTask task) async {
    await FileDownloader().resume(task);
  }

  Future<void> cancelDownload(String taskId) async {
    await FileDownloader().cancelTaskWithId(taskId);
  }

  Future<void> installUpdate() async {
    if (_downloadedApkPath == null) return;
    
    // We need to resolve the path properly for background_downloader
    final baseDir = await getApplicationDocumentsDirectory();
    final realPath = p.join(baseDir.path, 'updates', p.basename(_downloadedApkPath!));

    final file = File(realPath);
    if (!await file.exists()) {
       _notifier.updateState(_notifier.currentState.copyWith(
        status: UpdateStateStatus.error,
        errorMessage: 'APK file not found.',
      ));
      return;
    }

    _notifier.updateState(_notifier.currentState.copyWith(status: UpdateStateStatus.installing));
    
    final result = await OpenFilex.open(realPath);
    if (result.type != ResultType.done) {
      _notifier.updateState(_notifier.currentState.copyWith(
        status: UpdateStateStatus.error,
        errorMessage: 'Failed to launch installer: ${result.message}',
      ));
    } else {
      // Revert to downloaded state if installer is cancelled/closed
      _notifier.updateState(_notifier.currentState.copyWith(status: UpdateStateStatus.downloaded));
    }
  }

  void _notifyReadyToInstall() {
    // Note: To fully satisfy the native notification, background_downloader handles
    // basic download notifications natively if configured. For "Ready to Install"
    // tap-to-install, we can use local notifications, but for simplicity, we 
    // will just auto-launch the installer once downloaded if the app is open.
    installUpdate();
  }
}
