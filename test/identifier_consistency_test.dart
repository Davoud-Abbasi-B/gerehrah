import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pathly/share/app_share_service.dart';

void main() {
  const expectedIdentifier = 'com.damostudio.pathly';
  final retiredIdentifier = ['com', 'pathlygame', 'pathly'].join('.');

  test('Android and Dart use the publication identifier and share channel', () {
    const expectedChannel = '$expectedIdentifier/share';
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final activity = File(
      'android/app/src/main/kotlin/com/damostudio/pathly/MainActivity.kt',
    ).readAsStringSync();

    expect(pathlyShareChannelName, expectedChannel);
    expect(gradle, contains('namespace = "$expectedIdentifier"'));
    expect(gradle, contains('applicationId = "$expectedIdentifier"'));
    expect(activity, contains('package $expectedIdentifier'));
    expect(activity, contains('SHARE_CHANNEL = "$expectedChannel"'));
  });

  test('runtime Android and Dart sources contain no retired identifier', () {
    final sourceFiles = <File>[
      ...Directory('lib').listSync(recursive: true).whereType<File>(),
      ...Directory('android/app/src/main')
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (file) =>
                const {'.kt', '.xml'}.any(file.path.toLowerCase().endsWith),
          ),
    ];

    for (final file in sourceFiles) {
      expect(
        file.readAsStringSync(),
        isNot(contains(retiredIdentifier)),
        reason: file.path,
      );
    }
  });
}
