import 'package:equatable/equatable.dart';
import '../../domain/entities/app_release.dart';

abstract class AppUpdateState extends Equatable {
  final String installedVersion;

  const AppUpdateState({this.installedVersion = ''});

  bool get hasUnskippedUpdate => false;

  @override
  List<Object?> get props => [installedVersion];
}

class AppUpdateInitial extends AppUpdateState {
  const AppUpdateInitial({super.installedVersion = ''});
}

class AppUpdateChecking extends AppUpdateState {
  final bool isManual;

  const AppUpdateChecking({
    required this.isManual,
    super.installedVersion = '',
  });

  @override
  List<Object?> get props => [isManual, installedVersion];
}

class AppUpdateAvailable extends AppUpdateState {
  final AppRelease release;
  final bool isSkipped;

  const AppUpdateAvailable({
    required super.installedVersion,
    required this.release,
    this.isSkipped = false,
  });

  @override
  bool get hasUnskippedUpdate => !isSkipped;

  @override
  List<Object?> get props => [installedVersion, release, isSkipped];
}

class AppUpdateUpToDate extends AppUpdateState {
  final AppRelease? release;

  const AppUpdateUpToDate({
    required super.installedVersion,
    this.release,
  });

  @override
  List<Object?> get props => [installedVersion, release];
}

class AppUpdateNoReleases extends AppUpdateState {
  const AppUpdateNoReleases({
    required super.installedVersion,
  });
}

class AppUpdateError extends AppUpdateState {
  final String message;
  final bool isManual;

  const AppUpdateError({
    required this.message,
    required this.isManual,
    super.installedVersion = '',
  });

  @override
  List<Object?> get props => [message, isManual, installedVersion];
}

