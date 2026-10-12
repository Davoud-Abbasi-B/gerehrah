import 'package:flutter/services.dart';

const pathlyShareMessage =
    'Try Pathly — a relaxing path-connecting puzzle game!\n\n'
    'https://play.google.com/store/apps/details?id=com.damostudio.pathly';
const pathlyShareChannelName = 'com.damostudio.pathly/share';
const pathlyShareMethodName = 'shareText';

abstract interface class AppShareService {
  Future<void> shareApp({Rect? sharePositionOrigin});
}

class PlatformAppShareService implements AppShareService {
  const PlatformAppShareService();

  static const MethodChannel _channel = MethodChannel(pathlyShareChannelName);

  @override
  Future<void> shareApp({Rect? sharePositionOrigin}) async {
    await _channel.invokeMethod<void>(
      pathlyShareMethodName,
      const <String, Object>{'text': pathlyShareMessage},
    );
  }
}
