import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

/// The range calendar resolves its initial scroll offset (and every jump)
/// from deterministic per-month extents via `itemExtentBuilder`. These tests
/// verify the extent math matches the actual item layout: if the computed
/// heights drifted from reality, scrolling would land between months.
void main() {
  Future<void> pumpPicker(
    WidgetTester tester, {
    required DateTime firstDate,
    DateTime? initialStartDate,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: M3ETheme(
          data: M3EThemeData.light(),
          child: Scaffold(
            body: SizedBox(
              height: 480,
              child: M3ECalendarDateRangePicker(
                firstDate: firstDate,
                lastDate: DateTime(firstDate.year + 3, firstDate.month, 1),
                currentDate: DateTime(2026, 8, 28),
                initialStartDate: initialStartDate,
                onStartDateChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('opens anchored on the current month with a wide span', (
    tester,
  ) async {
    // 26 months of history: the anchor jump must not lay out intermediate
    // months (itemExtentBuilder) and must land exactly on August 2026.
    await pumpPicker(tester, firstDate: DateTime(2024, 7, 1));

    expect(find.text('August 2026'), findsOneWidget);
    expect(find.text('July 2024'), findsNothing);
  });

  testWidgets('scrolling to the top lands exactly on the first month', (
    tester,
  ) async {
    await pumpPicker(tester, firstDate: DateTime(2024, 7, 1));

    // Fling up repeatedly to reach the top of the list.
    for (var i = 0; i < 12; i++) {
      await tester.fling(find.byType(M3ECalendarDateRangePicker), const Offset(0, 600), 4000);
      await tester.pumpAndSettle();
    }

    // The first month's title is at the very top of the list — only exact
    // extent math puts it flush at offset 0.
    expect(find.text('July 2024'), findsOneWidget);
  });

  testWidgets('opens anchored on the selected start month', (tester) async {
    await pumpPicker(
      tester,
      firstDate: DateTime(2024, 7, 1),
      initialStartDate: DateTime(2025, 3, 10),
    );

    expect(find.text('March 2025'), findsOneWidget);
  });
}
