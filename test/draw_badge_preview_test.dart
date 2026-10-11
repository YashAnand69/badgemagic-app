import 'package:badgemagic/providers/draw_badge_provider.dart';
import 'package:badgemagic/view/widgets/badge_paint.dart';
import 'package:badgemagic/view/widgets/draw_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final shape in [
    DrawShape.square,
    DrawShape.rectangle,
    DrawShape.circle,
    DrawShape.triangle,
  ]) {
    testWidgets('$shape is painted while dragging before commit', (
      tester,
    ) async {
      late DrawBadgeProvider provider;
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 440,
              child: BMBadge(
                providerInit: (value) {
                  provider = value;
                  provider.setShape(shape);
                },
              ),
            ),
          ),
        ),
      );

      final badge = find.byType(BMBadge);
      final gesture = await tester.startGesture(tester.getCenter(badge));
      await gesture.moveBy(const Offset(24, 0));
      await tester.pump();
      var previewNotifications = 0;
      provider.addListener(() => previewNotifications++);
      await gesture.moveBy(const Offset(24, 24));
      await tester.pump();

      final paint = tester.widget<CustomPaint>(
        find.descendant(of: badge, matching: find.byType(CustomPaint)),
      );
      final preview = (paint.painter! as BadgePaint).grid;
      expect(preview.expand((row) => row).any((value) => value), isTrue);
      expect(preview, provider.getDrawViewGrid());
      expect(previewNotifications, 1);

      await gesture.up();
      await tester.pump();
      expect(provider.getDrawViewGrid(), preview);
      provider.undo();
      expect(
        provider.getDrawViewGrid().expand((row) => row).any((v) => v),
        isFalse,
      );
    });
    testWidgets('$shape preserves accepted-drag cancellation behavior',
        (tester) async {
      late DrawBadgeProvider provider;
      await tester.pumpWidget(MaterialApp(
        home: Center(
          child: SizedBox(
            width: 440,
            child: BMBadge(providerInit: (value) {
              provider = value;
              provider.setShape(shape);
              provider.setCell(0, 0, true);
            }),
          ),
        ),
      ));
      final committed = provider.getDrawViewGrid();
      final badge = find.byType(BMBadge);
      final gesture = await tester.startGesture(tester.getCenter(badge));
      await gesture.moveBy(const Offset(24, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(24, 24));
      await tester.pump();
      final preview = provider.getDrawViewGrid();
      expect(preview, isNot(committed));

      await gesture.cancel();
      await tester.pump();
      expect(provider.getDrawViewGrid(), preview);
      final paint = tester.widget<CustomPaint>(find.descendant(
        of: badge,
        matching: find.byType(CustomPaint),
      ));
      expect((paint.painter! as BadgePaint).grid, preview);
      provider.undo();
      expect(provider.getDrawViewGrid(), committed);
    });
  }
}
