import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(Widget child) => MaterialApp(
  home: M3ETheme(
    data: M3EThemeData.light(),
    child: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('search view focuses the field on first expansion', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(900, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final controller = M3ESearchController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _app(
        M3ESearchAnchor.bar(
          searchController: controller,
          barHintText: 'Search',
          suggestionsBuilder: (context, controller) async => const <Widget>[],
        ),
      ),
    );

    controller.openView();
    await tester.pump();
    await tester.pump();

    final EditableText field = tester.widget<EditableText>(
      find.descendant(
        of: find.byWidgetPredicate(
          (Widget widget) => widget is M3ESearchBar && !widget.readOnly,
        ),
        matching: find.byType(EditableText),
      ),
    );
    expect(field.focusNode.hasPrimaryFocus, isTrue);
  });
}
