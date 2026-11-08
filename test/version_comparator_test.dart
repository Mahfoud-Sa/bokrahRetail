import 'package:flutter_test/flutter_test.dart';
import 'package:bokrah_retail/app/features/autoUpdate/data/utils/version_comparator.dart';

void main() {
  group('VersionComparator Tests', () {
    test('standard semver comparison', () {
      expect(VersionComparator.compare('1.0.0', '1.0.1'), lessThan(0));
      expect(VersionComparator.compare('1.0.1', '1.0.0'), greaterThan(0));
      expect(VersionComparator.compare('1.0.0', '1.0.0'), equals(0));
    });

    test('handles v prefix in versions', () {
      expect(VersionComparator.compare('v1.2.0', '1.3.0'), lessThan(0));
      expect(VersionComparator.compare('1.2.0', 'v1.1.0'), greaterThan(0));
    });

    test('handles versions of different lengths correctly', () {
      expect(VersionComparator.compare('1.0', '1.0.1'), lessThan(0));
      expect(VersionComparator.compare('1.0.0.1', '1.0.0'), greaterThan(0));
      expect(VersionComparator.compare('3.3', '3.3.0'), equals(0));
    });

    test('handles build numbers (+ suffix) and prerelease tags', () {
      expect(VersionComparator.compare('1.0.0+1', '1.0.0+2'), lessThan(0));
      expect(VersionComparator.compare('2.0.0', '2.0.0+5'), lessThan(0));
      expect(VersionComparator.compare('1.0.0-alpha', '1.0.0'), lessThan(0));
    });

    test('compares multi-digit minor versions numerically (1.10.0 > 1.9.0)', () {
      expect(VersionComparator.compare('1.10.0', '1.9.0'), greaterThan(0));
      expect(VersionComparator.compare('1.9.0', '1.10.0'), lessThan(0));
    });

    test('validates valid version strings', () {
      expect(VersionComparator.isValid('1.0.0'), isTrue);
      expect(VersionComparator.isValid('v3.4.0'), isTrue);
      expect(VersionComparator.isValid('3.3.0+12'), isTrue);
      expect(VersionComparator.isValid('1.2'), isTrue);
      expect(VersionComparator.isValid('2.0.0-beta.1'), isTrue);
    });

    test('rejects malformed versions', () {
      expect(VersionComparator.isValid(''), isFalse);
      expect(VersionComparator.isValid('abc'), isFalse);
      expect(VersionComparator.isValid('v.1.0'), isFalse);
      expect(VersionComparator.isValid('1.x.3'), isFalse);
    });

    test('throws FormatException on malformed version comparison', () {
      expect(() => VersionComparator.compare('invalid', '1.0.0'), throwsFormatException);
      expect(() => VersionComparator.compare('1.0.0', 'not-a-version'), throwsFormatException);
    });

    test('isNewer convenience method', () {
      expect(VersionComparator.isNewer('3.3.0', '3.4.0'), isTrue);
      expect(VersionComparator.isNewer('3.3.0', '3.3.0'), isFalse);
      expect(VersionComparator.isNewer('3.4.0', '3.3.0'), isFalse);
    });
  });
}
