import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/github_release.dart';
import '../services/update_service.dart';
import 'package:background_downloader/background_downloader.dart';

enum UpdateStateStatus {
  checking,
  upToDate,
  updateAvailable,
  downloading,
  paused,
  downloaded,
  installing,
  error
}

class UpdateState {
  final UpdateStateStatus status;
  final GithubRelease? latestRelease;
  final String currentVersion;
  final double downloadProgress;
  final String errorMessage;
  final double downloadSpeed; // in MB/s
  final double downloadedMB;
  final String timeRemaining;
  final DownloadTask? currentTask;

  const UpdateState({
    this.status = UpdateStateStatus.checking,
    this.latestRelease,
    this.currentVersion = '',
    this.downloadProgress = 0.0,
    this.errorMessage = '',
    this.downloadSpeed = 0.0,
    this.downloadedMB = 0.0,
    this.timeRemaining = '',
    this.currentTask,
  });

  UpdateState copyWith({
    UpdateStateStatus? status,
    GithubRelease? latestRelease,
    String? currentVersion,
    double? downloadProgress,
    String? errorMessage,
    double? downloadSpeed,
    double? downloadedMB,
    String? timeRemaining,
    DownloadTask? currentTask,
  }) {
    return UpdateState(
      status: status ?? this.status,
      latestRelease: latestRelease ?? this.latestRelease,
      currentVersion: currentVersion ?? this.currentVersion,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      errorMessage: errorMessage ?? this.errorMessage,
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
      downloadedMB: downloadedMB ?? this.downloadedMB,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      currentTask: currentTask ?? this.currentTask,
    );
  }
}

final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService(ref);
});

final updateStateProvider = NotifierProvider<UpdateNotifier, UpdateState>(() {
  return UpdateNotifier();
});

class UpdateNotifier extends Notifier<UpdateState> {
  late UpdateService _updateService;

  @override
  UpdateState build() {
    _updateService = ref.read(updateServiceProvider);
    // Initialize in a microtask to avoid modifying state during build
    Future.microtask(() {
      _updateService.init(this);
      checkForUpdates(silent: true);
    });
    return const UpdateState();
  }

  UpdateState get currentState => state;

  void updateState(UpdateState newState) {
    state = newState;
  }

  Future<void> checkForUpdates({bool silent = false}) async {
    state = state.copyWith(status: UpdateStateStatus.checking, errorMessage: '');
    await _updateService.checkForUpdates(silent: silent);
  }

  Future<void> downloadUpdate() async {
    if (state.latestRelease == null) return;
    await _updateService.downloadUpdate(state.latestRelease!);
  }

  Future<void> pauseDownload() async {
    if (state.currentTask != null) {
      await _updateService.pauseDownload(state.currentTask!);
    }
  }

  Future<void> resumeDownload() async {
    if (state.currentTask != null) {
      await _updateService.resumeDownload(state.currentTask!);
    }
  }

  Future<void> cancelDownload() async {
    if (state.currentTask != null) {
      await _updateService.cancelDownload(state.currentTask!.taskId);
    }
    state = state.copyWith(
      status: UpdateStateStatus.updateAvailable, 
      downloadProgress: 0.0,
      downloadedMB: 0.0,
      downloadSpeed: 0.0,
      timeRemaining: '',
    );
  }

  Future<void> installUpdate() async {
    await _updateService.installUpdate();
  }
}
