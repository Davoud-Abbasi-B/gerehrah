import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _appBackground = Color(0xFF08111F);
const _markBackground = Color(0xFF172A45);
const _markBorder = Color(0xFF315783);
const _markForeground = Color(0xFF76A9FF);

void main() {
  testWidgets('generate Pathly Android launcher icons', (tester) async {
    await _loadMaterialIcons();
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
        size: legacySize,
        output: 'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png',
        backgroundShape: BoxShape.rectangle,
        markFraction: 0.62,
      );
      await _render(
        tester,
        size: legacySize,
        output:
            'android/app/src/main/res/mipmap-${entry.key}/'
            'ic_launcher_round.png',
        backgroundShape: BoxShape.circle,
        markFraction: 0.62,
      );
      await _render(
        tester,
        size: foregroundSize,
        output:
            'android/app/src/main/res/drawable-${entry.key}/'
            'ic_launcher_foreground.png',
        markFraction: 60 / 108,
      );
      // ignore: avoid_print
      print('Generated ${entry.key} launcher resources.');
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _loadMaterialIcons() async {
  var directory = File(Platform.resolvedExecutable).parent;
  while (true) {
    final font = File(
      '${directory.path}/bin/cache/artifacts/material_fonts/'
      'materialicons-regular.otf',
    );
    if (font.existsSync()) {
      final bytes = font.readAsBytesSync();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(Future.value(bytes.buffer.asByteData()))).load();
      return;
    }
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('Unable to locate Flutter Material Icons font.');
    }
    directory = parent;
  }
}

Future<void> _render(
  WidgetTester tester, {
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
            child: Center(child: _PathlyMark(size: size * markFraction)),
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
  });
}

class _PathlyMark extends StatelessWidget {
  const _PathlyMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _markBackground,
        borderRadius: BorderRadius.circular(size * 12 / 38),
        border: Border.all(
          color: _markBorder,
          width: (size / 38).clamp(1, double.infinity),
        ),
      ),
      child: Icon(
        Icons.route_rounded,
        color: _markForeground,
        size: size * 24 / 38,
      ),
    );
  }
}
