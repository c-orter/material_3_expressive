import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(Widget child) => MaterialApp(
  home: M3ETheme(
    data: M3EThemeData.light(),
    child: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  testWidgets('input date field takes focus when autofocus is set', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        M3EInputDatePickerFormField(
          firstDate: DateTime(2024),
          lastDate: DateTime(2030),
          autofocus: true,
        ),
      ),
    );
    await tester.pump();

    final EditableText field = tester.widget<EditableText>(
      find.byType(EditableText),
    );
    expect(field.focusNode.hasPrimaryFocus, isTrue);
  });
}
