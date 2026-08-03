import 'dart:io';

void main() {
  final files = [
    'lib/screens/home/discover_feed_screen.dart',
    'lib/screens/profile/my_profile_screen.dart',
    'lib/screens/profile/edit_profile_screen.dart',
    'lib/screens/profile/subscription_screen.dart',
  ];

  final regex1 = RegExp(r'const\s+SizedBox\(\s*height:\s*(\d+(?:\.\d+)?)\s*\)');
  final regex2 = RegExp(r'(?<!const\s)SizedBox\(\s*height:\s*(\d+(?:\.\d+)?)\s*\)');

  for (final filePath in files) {
    final file = File(filePath);
    if (!file.existsSync()) {
      print('File not found: $filePath');
      continue;
    }

    String content = file.readAsStringSync();
    
    // Replace const SizedBox(height: X)
    content = content.replaceAllMapped(regex1, (match) {
      return 'SizedBox(height: context.responsiveHeight(${match.group(1)}))';
    });

    // Replace SizedBox(height: X) (non-const)
    content = content.replaceAllMapped(regex2, (match) {
      return 'SizedBox(height: context.responsiveHeight(${match.group(1)}))';
    });

    // Add import if not present
    if (!content.contains('responsive_utils.dart')) {
      // Find the last import and add it after
      final importRegex = RegExp(r"import\s+'[^']+';");
      final matches = importRegex.allMatches(content);
      if (matches.isNotEmpty) {
        final lastMatch = matches.last;
        final insertIndex = lastMatch.end;
        // Check relative path depth based on slashes in file path
        final depth = filePath.split('/').length - 2;
        final prefix = depth > 0 ? '../' * depth : '';
        final importStr = "\nimport '${prefix}utils/responsive_utils.dart';";
        content = content.substring(0, insertIndex) + importStr + content.substring(insertIndex);
      }
    }

    file.writeAsStringSync(content);
    print('Updated $filePath');
  }
}
