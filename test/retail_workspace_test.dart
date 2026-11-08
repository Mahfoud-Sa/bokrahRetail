import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bokrah_retail/main.dart';

void main() {
  testWidgets('shows the Retail catalog from the desktop workspace', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BokrahRetailApp());

    expect(find.text('Open catalog'), findsOneWidget);

    await tester.tap(find.text('Catalog').first);
    await tester.pumpAndSettle();

    expect(find.text('Product catalog'), findsOneWidget);
    expect(find.text('Canvas Tote'), findsOneWidget);
  });
}
