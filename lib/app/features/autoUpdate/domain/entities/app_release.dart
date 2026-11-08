import 'package:equatable/equatable.dart';

class AppRelease extends Equatable {
  final String version;
  final String tagName;
  final String name;
  final String body;
  final DateTime? publishedAt;
  final String? downloadUrl;
  final String? htmlUrl;

  const AppRelease({
    required this.version,
    required this.tagName,
    required this.name,
    required this.body,
    this.publishedAt,
    this.downloadUrl,
    this.htmlUrl,
  });

  @override
  List<Object?> get props => [
        version,
        tagName,
        name,
        body,
        publishedAt,
        downloadUrl,
        htmlUrl,
      ];
}
