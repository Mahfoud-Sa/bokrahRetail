class VersionComparator {
  VersionComparator._();

  static final RegExp _versionRegex = RegExp(
    r'^v?(\d+)(\.\d+)*(?:-([0-9A-Za-z.-]+))?(?:\+([0-9A-Za-z.-]+))?$',
    caseSensitive: false,
  );

  /// Checks if [version] is a syntactically valid semantic/release version string.
  static bool isValid(String version) {
    final trimmed = version.trim();
    if (trimmed.isEmpty) return false;
    return _versionRegex.hasMatch(trimmed);
  }

  /// Compares two version strings [v1] and [v2].
  /// Returns negative if v1 < v2, zero if v1 == v2, positive if v1 > v2.
  /// Throws [FormatException] if either version string is malformed.
  static int compare(String v1, String v2) {
    if (!isValid(v1)) {
      throw FormatException('Malformed version: "$v1"');
    }
    if (!isValid(v2)) {
      throw FormatException('Malformed version: "$v2"');
    }

    final clean1 = _clean(v1);
    final clean2 = _clean(v2);

    final parts1 = _parseComponents(clean1);
    final parts2 = _parseComponents(clean2);

    final maxLength = parts1.length > parts2.length ? parts1.length : parts2.length;

    for (int i = 0; i < maxLength; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;

      if (p1 < p2) return -1;
      if (p1 > p2) return 1;
    }

    // If numeric parts match, handle prereleases / build numbers
    final build1 = _parseBuildNumber(v1);
    final build2 = _parseBuildNumber(v2);
    if (build1 != build2) {
      return build1.compareTo(build2);
    }

    final hasPre1 = v1.contains('-');
    final hasPre2 = v2.contains('-');
    if (hasPre1 && !hasPre2) return -1;
    if (!hasPre1 && hasPre2) return 1;

    return 0;
  }

  static bool isNewer(String installed, String latest) {
    return compare(installed, latest) < 0;
  }

  static String _clean(String version) {
    var v = version.trim();
    if (v.startsWith('v') || v.startsWith('V')) {
      v = v.substring(1);
    }
    // Remove build metadata and prerelease tags for primary numeric comparison
    final plusIndex = v.indexOf('+');
    if (plusIndex != -1) {
      v = v.substring(0, plusIndex);
    }
    final dashIndex = v.indexOf('-');
    if (dashIndex != -1) {
      v = v.substring(0, dashIndex);
    }
    return v;
  }

  static List<int> _parseComponents(String cleaned) {
    return cleaned
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
  }

  static int _parseBuildNumber(String version) {
    final plusIndex = version.indexOf('+');
    if (plusIndex != -1 && plusIndex < version.length - 1) {
      final buildStr = version.substring(plusIndex + 1);
      return int.tryParse(buildStr) ?? 0;
    }
    return 0;
  }
}
