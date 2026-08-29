import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) {
  return MaterialApp(
    home: M3ETheme(
      data: M3EThemeData.light(),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  testWidgets(
    'M3ECalendarDateRangePicker opens on the current month when no start date',
    (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            height: 480,
            child: M3ECalendarDateRangePicker(
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              currentDate: DateTime(2026, 8, 28),
              onStartDateChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The current month header is visible without scrolling; the first
      // month (January 2000) is far off-screen above.
      expect(find.text('August 2026'), findsOneWidget);
      expect(find.text('January 2000'), findsNothing);
    },
  );

  testWidgets('M3ECalendarDateRangePicker opens on the selected start month', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          height: 480,
          child: M3ECalendarDateRangePicker(
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            currentDate: DateTime(2026, 8, 28),
            initialStartDate: DateTime(2025, 3, 10),
            onStartDateChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('March 2025'), findsOneWidget);
    expect(find.text('January 2000'), findsNothing);
  });
}
