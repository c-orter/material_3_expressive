import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets(
    'M3EDatePicker.showRange opens anchored with a wide firstDate gap',
    (tester) async {
      final first = DateTime(2000);
      final last = DateTime.now().add(const Duration(days: 365));

      await tester.pumpWidget(
        MaterialApp(
          home: M3ETheme(
            data: M3EThemeData.light(),
            child: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: M3EButton(
                    onPressed: () {
                      M3EDatePicker.showRange(
                        context,
                        firstDate: first,
                        lastDate: last,
                      );
                    },
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      // A timeout here means the dialog build/layout never settles (freeze).
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // The dialog must open on the current month, not January 2000.
      final currentMonth = MaterialLocalizations.of(
        tester.element(find.byType(M3EDateRangePickerDialog)),
      ).formatMonthYear(DateTime.now());
      expect(find.text(currentMonth), findsOneWidget);
    },
  );
}
