// One-off generator for the app icon and splash logo, rendered from the
// in-app theme colors so they stay consistent with AppColors. Not part of the
// regular test suite (lives under tool/, not test/) — run manually with
// `flutter test tool/generate_brand_assets_test.dart` after changing the mark.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _navy = Color(0xFF1B2A41);
const _cream = Color(0xFFF5F1E8);
const _bronze = Color(0xFF8B6F47);

class _Mark extends StatelessWidget {
  final double canvasSize;
  final double squareSize;
  final bool transparentBg;
  const _Mark({
    required this.canvasSize,
    required this.squareSize,
    this.transparentBg = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: canvasSize,
      height: canvasSize,
      color: transparentBg ? null : _cream,
      alignment: Alignment.center,
      child: Container(
        width: squareSize,
        height: squareSize,
        decoration: BoxDecoration(
          color: _navy,
          borderRadius: BorderRadius.circular(squareSize * 0.22),
        ),
        alignment: Alignment.center,
        child: Text(
          'P',
          style: TextStyle(
            color: _bronze,
            fontSize: squareSize * 0.6,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

Future<void> _capture(
  WidgetTester tester, {
  required Widget widget,
  required double size,
  required String path,
}) async {
  tester.view.physicalSize = Size(size, size);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(key: key, child: widget),
    ),
  );
  await tester.pumpAndSettle();

  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(path);
    file.parent.createSync(recursive: true);
    await file.writeAsBytes(byteData!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('generate app icon', (tester) async {
    await _capture(
      tester,
      widget: const _Mark(canvasSize: 1024, squareSize: 760),
      size: 1024,
      path: 'assets/icon/icon.png',
    );
  });

  testWidgets('generate splash logo', (tester) async {
    await _capture(
      tester,
      widget: const _Mark(canvasSize: 512, squareSize: 320, transparentBg: true),
      size: 512,
      path: 'assets/splash/splash_logo.png',
    );
  });
}
