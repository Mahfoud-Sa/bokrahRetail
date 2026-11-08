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
      return jsonList.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch releases from GitHub: ${response.statusCode} ${response.reasonPhrase}');
    }
  }
}
