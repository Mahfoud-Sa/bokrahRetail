import 'package:equatable/equatable.dart';
import '../../domain/entities/app_release.dart';

abstract class AppUpdateState extends Equatable {
  const AppUpdateState();

  bool get hasUnskippedUpdate => false;

  @override
  List<Object?> get props => [];
}

class AppUpdateInitial extends AppUpdateState {
  final String installedVersion;

  const AppUpdateInitial({this.installedVersion = ''});

  @override
  List<Object?> get props => [installedVersion];
}

class AppUpdateChecking extends AppUpdateState {
  final bool isManual;
  final String installedVersion;

  const AppUpdateChecking({
    required this.isManual,
    this.installedVersion = '',
  });

  @override
  List<Object?> get props => [isManual, installedVersion];
}

class AppUpdateAvailable extends AppUpdateState {
  final String installedVersion;
  final AppRelease release;
  final bool isSkipped;

  const AppUpdateAvailable({
    required this.installedVersion,
    required this.release,
    this.isSkipped = false,
  });

  @override
  bool get hasUnskippedUpdate => !isSkipped;

  @override
  List<Object?> get props => [installedVersion, release, isSkipped];
}

class AppUpdateUpToDate extends AppUpdateState {
  final String installedVersion;
  final AppRelease? release;

  const AppUpdateUpToDate({
    required this.installedVersion,
    this.release,
  });

  @override
  List<Object?> get props => [installedVersion, release];
}

class AppUpdateNoReleases extends AppUpdateState {
  final String installedVersion;

  const AppUpdateNoReleases({
    required this.installedVersion,
  });

  @override
  List<Object?> get props => [installedVersion];
}

class AppUpdateError extends AppUpdateState {
  final String message;
  final bool isManual;
  final String installedVersion;

  const AppUpdateError({
    required this.message,
    required this.isManual,
    this.installedVersion = '',
  });

  @override
  List<Object?> get props => [message, isManual, installedVersion];
}
