import 'package:flutter_test/flutter_test.dart';
import 'package:frnds/models/app_version.dart';

void main() {
  group('AppVersion.compareVersions', () {
    test('equal versions should return 0', () {
      expect(AppVersion.compareVersions('1.0.0', '1.0.0'), equals(0));
      expect(AppVersion.compareVersions('2.5.12', '2.5.12'), equals(0));
    });

    test('patch increment', () {
      expect(AppVersion.compareVersions('1.0.0', '1.0.1'), lessThan(0));
      expect(AppVersion.compareVersions('1.0.1', '1.0.0'), greaterThan(0));
    });

    test('minor increment', () {
      expect(AppVersion.compareVersions('1.0.0', '1.1.0'), lessThan(0));
      expect(AppVersion.compareVersions('1.1.0', '1.0.0'), greaterThan(0));
    });

    test('major increment', () {
      expect(AppVersion.compareVersions('1.0.0', '2.0.0'), lessThan(0));
      expect(AppVersion.compareVersions('2.0.0', '1.0.0'), greaterThan(0));
    });

    test('two-digit vs one-digit segment', () {
      // Lexicographic string comparison would fail here (e.g., '1.10.0' < '1.9.0' is true for strings).
      // Semantic versioning handles this correctly.
      expect(AppVersion.compareVersions('1.9.0', '1.10.0'), lessThan(0));
      expect(AppVersion.compareVersions('1.10.0', '1.9.0'), greaterThan(0));
      expect(AppVersion.compareVersions('2.0.9', '2.0.10'), lessThan(0));
    });

    test('invalid/malformed versions should default to 0 (fail open)', () {
      // We expect the catch block to return 0 for invalid formats to prevent app crashes.
      expect(AppVersion.compareVersions('invalid', '1.0.0'), equals(0));
      expect(AppVersion.compareVersions('1.0.0', 'invalid'), equals(0));
      expect(AppVersion.compareVersions('1.0', '1.0.0'), equals(0)); // version package expects strictly x.y.z
    });
  });
}
