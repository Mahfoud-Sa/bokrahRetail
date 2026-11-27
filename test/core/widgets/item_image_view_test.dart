import 'dart:convert';

import 'package:bokrah_retail/app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 1x1 transparent PNG
  final onePixelPngBase64 = base64Encode(const <int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
    0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
    0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
  ]);

  group('ItemImageView', () {
    testWidgets('renders fallback when source is empty or missing', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ItemImageView(source: '', fallback: Text('fallback-widget')),
          ),
        ),
      );

      expect(find.text('fallback-widget'), findsOneWidget);
    });

    testWidgets('renders Image.memory for data:image base64 URI', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemImageView(
              source: 'data:image/png;base64,$onePixelPngBase64',
            ),
          ),
        ),
      );

      final imageWidget = tester.widget<Image>(find.byType(Image));
      expect(imageWidget.image, isA<MemoryImage>());
    });
  });

  group('ItemMediaSection', () {
    testWidgets(
      'shows desktop upload buttons for main, sub images, and video',
      (tester) async {
        final mainCtrl = TextEditingController();
        final videoCtrl = TextEditingController();
        addTearDown(() {
          mainCtrl.dispose();
          videoCtrl.dispose();
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ItemMediaSection(
                  mainImageController: mainCtrl,
                  subImages: const [],
                  onSubImagesChanged: (_) {},
                  videoController: videoCtrl,
                ),
              ),
            ),
          ),
        );

        expect(find.text('رفع من الجهاز'), findsNWidgets(3));
        expect(find.text('إضافة رابط'), findsOneWidget);
      },
    );
  });
}
