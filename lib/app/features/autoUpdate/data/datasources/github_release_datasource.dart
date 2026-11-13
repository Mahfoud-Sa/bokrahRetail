import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../config/app_config.dart';

abstract class GithubReleaseDatasource {
  Future<List<Map<String, dynamic>>> fetchReleases();
}

class HttpGithubReleaseDatasource implements GithubReleaseDatasource {
  final http.Client _client;
  final String owner;
  final String repo;

  HttpGithubReleaseDatasource({
    http.Client? client,
    this.owner = AppConfig.githubRepoOwner,
    this.repo = AppConfig.githubRepoName,
  }) : _client = client ?? http.Client();

  @override
  Future<List<Map<String, dynamic>>> fetchReleases() async {
    final uri = Uri.parse('https://api.github.com/repos/$owner/$repo/releases');
    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'Bokrah-App',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      final list = jsonList.cast<Map<String, dynamic>>();
      if (list.isNotEmpty) {
        return list;
      }
    }

    // Resilient fallback: If querying bokrahRetail or bokrah and no releases were found,
    // try the sibling repository to discover published releases.
    if (owner == 'Mahfoud-Sa') {
      final fallbackRepo = repo == 'bokrahRetail' ? 'bokrah' : (repo == 'bokrah' ? 'bokrahRetail' : null);
      if (fallbackRepo != null) {
        try {
          final fallbackUri = Uri.parse('https://api.github.com/repos/$owner/$fallbackRepo/releases');
          final fallbackResponse = await _client.get(
            fallbackUri,
            headers: {
              'Accept': 'application/vnd.github.v3+json',
              'User-Agent': 'Bokrah-App',
            },
          );
          if (fallbackResponse.statusCode == 200) {
            final List<dynamic> fallbackList = json.decode(fallbackResponse.body);
            final casted = fallbackList.cast<Map<String, dynamic>>();
            if (casted.isNotEmpty) {
              return casted;
            }
          }
        } catch (_) {
          // If fallback fails, continue to default error handling
        }
      }
    }

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch releases from GitHub: ${response.statusCode} ${response.reasonPhrase}');
    }
  }
}
