import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/app_update_repository.dart';
import 'app_update_state.dart';

class AppUpdateCubit extends Cubit<AppUpdateState> {
  final AppUpdateRepository _repository;

  AppUpdateCubit({required AppUpdateRepository repository})
      : _repository = repository,
        super(const AppUpdateInitial());

  String get _currentInstalledVersion {
    final s = state;
    if (s is AppUpdateInitial) return s.installedVersion;
    if (s is AppUpdateChecking) return s.installedVersion;
    if (s is AppUpdateAvailable) return s.installedVersion;
    if (s is AppUpdateUpToDate) return s.installedVersion;
    if (s is AppUpdateNoReleases) return s.installedVersion;
    if (s is AppUpdateError) return s.installedVersion;
    return '';
  }

  Future<void> checkForUpdates({bool isManual = false}) async {
    // Avoid duplicate concurrent update checks
    if (state is AppUpdateChecking) return;

    final currentInstalled = _currentInstalledVersion;

    emit(AppUpdateChecking(
      isManual: isManual,
      installedVersion: currentInstalled,
    ));

    String installedVersion = currentInstalled;
    try {
      final fetched = await _repository.getInstalledVersion();
      if (fetched.isNotEmpty) {
        installedVersion = fetched;
      }
    } catch (_) {
      // Do not fake '0.0.0'; preserve existing or empty
    }

    if (installedVersion.isEmpty) {
      if (isManual) {
        emit(const AppUpdateError(
          message: 'Could not determine installed application version',
          isManual: true,
          installedVersion: '',
        ));
      } else {
        emit(const AppUpdateInitial(installedVersion: ''));
      }
      return;
    }

    try {
      final latestRelease = await _repository.getLatestRelease();

      if (latestRelease == null) {
        emit(AppUpdateNoReleases(
          installedVersion: installedVersion,
        ));
        return;
      }

      final isAvailable = _repository.isUpdateAvailable(
        installedVersion,
        latestRelease.version,
      );

      if (isAvailable) {
        final isSkipped = await _repository.isVersionSkipped(latestRelease.version);
        emit(AppUpdateAvailable(
          installedVersion: installedVersion,
          release: latestRelease,
          isSkipped: isSkipped,
        ));
      } else {
        emit(AppUpdateUpToDate(
          installedVersion: installedVersion,
          release: latestRelease,
        ));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppUpdateCubit] Update check failed: $e');
      }

      if (isManual) {
        emit(AppUpdateError(
          message: e.toString().replaceFirst('Exception: ', ''),
          isManual: true,
          installedVersion: installedVersion,
        ));
      } else {
        // Silent failure for background checks: fallback to Initial with installed version
        emit(AppUpdateInitial(installedVersion: installedVersion));
      }
    }
  }

  Future<void> skipVersion(String version) async {
    await _repository.skipVersion(version);
    final currentState = state;
    if (currentState is AppUpdateAvailable) {
      emit(AppUpdateAvailable(
        installedVersion: currentState.installedVersion,
        release: currentState.release,
        isSkipped: true,
      ));
    }
  }

  Future<bool> launchDownload(String url) async {
    return await _repository.launchDownloadUrl(url);
  }
}
