import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _appBackground = Color(0xFF08111F);

void main() {
  testWidgets('generate Gerehrah Android launcher icons', (tester) async {
    // Run explicitly with: flutter test tool/generate_android_launcher_icons_test.dart
    // Keep the source logo intact; center it inside the adaptive safe zone.
    late ui.Image logo;
    await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(
        File('assets/gerehrah_icon.png').readAsBytesSync(),
      );
      logo = (await codec.getNextFrame()).image;
      codec.dispose();
    });
    addTearDown(logo.dispose);
    const densities = {
      'mdpi': 1.0,
      'hdpi': 1.5,
      'xhdpi': 2.0,
      'xxhdpi': 3.0,
      'xxxhdpi': 4.0,
    };

    for (final entry in densities.entries) {
      final legacySize = (48 * entry.value).round();
      final foregroundSize = (108 * entry.value).round();
      await _render(
        tester,
        logo: logo,
        size: legacySize,
        output: 'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png',
        backgroundShape: BoxShape.rectangle,
        markFraction: 0.90,
      );
      await _render(
        tester,
        logo: logo,
        size: legacySize,
        output:
            'android/app/src/main/res/mipmap-${entry.key}/'
            'ic_launcher_round.png',
        backgroundShape: BoxShape.circle,
        markFraction: 0.70,
      );
      await _render(
        tester,
        logo: logo,
        size: foregroundSize,
        output:
            'android/app/src/main/res/drawable-${entry.key}/'
            'ic_launcher_foreground.png',
        markFraction: 46 / 108,
      );
      // ignore: avoid_print
      print('Generated ${entry.key} launcher resources.');
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _render(
  WidgetTester tester, {
  required ui.Image logo,
  required int size,
  required String output,
  required double markFraction,
  BoxShape? backgroundShape,
}) async {
  final repaintKey = GlobalKey();
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size.square(size.toDouble());

  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: repaintKey,
        child: SizedBox.square(
          dimension: size.toDouble(),
          child: DecoratedBox(
            decoration: backgroundShape == null
                ? const BoxDecoration()
                : BoxDecoration(color: _appBackground, shape: backgroundShape),
            child: Center(
              child: SizedBox.square(
                dimension: size * markFraction,
                child: RawImage(image: logo, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();

  final boundary =
      repaintKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(output);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
