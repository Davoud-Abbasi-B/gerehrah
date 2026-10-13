import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gerehrah/share/app_share_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(gerehrahShareChannelName);
  const expectedShareMessage =
      'گره‌راه رو امتحان کن؛ نقطه‌های هم‌رنگ رو وصل کن و همهٔ صفحه رو پر کن!\n\n'
      'https://cafebazaar.ir/app/com.damostudio.gerehrah';

  test('share channel uses the publication application identifier', () {
    expect(gerehrahShareChannelName, 'com.damostudio.gerehrah/share');
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'platform service sends the configured text over the native channel',
    () async {
      MethodCall? receivedCall;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            receivedCall = call;
            return null;
          });

      await const PlatformAppShareService().shareApp();

      expect(receivedCall?.method, gerehrahShareMethodName);
      expect(receivedCall?.arguments, const <String, Object>{
        'text': expectedShareMessage,
      });
      expect(gerehrahShareMessage, expectedShareMessage);
    },
  );

  test(
    'platform service exposes genuine native errors to the UI layer',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (_) => throw PlatformException(code: 'SHARE_FAILED'),
          );

      expect(
        const PlatformAppShareService().shareApp(),
        throwsA(
          isA<PlatformException>().having(
            (error) => error.code,
            'code',
            'SHARE_FAILED',
          ),
        ),
      );
    },
  );
}
