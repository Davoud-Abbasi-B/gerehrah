import 'package:flutter/services.dart';

const gerehrahShareMessage =
    'گره‌راه رو امتحان کن؛ نقطه‌های هم‌رنگ رو وصل کن و همهٔ صفحه رو پر کن!\n\n'
    'https://cafebazaar.ir/app/com.damostudio.gerehrah';
const gerehrahShareChannelName = 'com.damostudio.gerehrah/share';
const gerehrahShareMethodName = 'shareText';

abstract interface class AppShareService {
  Future<void> shareApp({Rect? sharePositionOrigin});
}

class PlatformAppShareService implements AppShareService {
  const PlatformAppShareService();

  static const MethodChannel _channel = MethodChannel(gerehrahShareChannelName);

  @override
  Future<void> shareApp({Rect? sharePositionOrigin}) async {
    await _channel.invokeMethod<void>(
      gerehrahShareMethodName,
      const <String, Object>{'text': gerehrahShareMessage},
    );
  }
}
