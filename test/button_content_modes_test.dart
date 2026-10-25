import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

const String _label = 'Label';
const String _iconSemantic = 'Icon action';

Widget _host(Widget child) => MaterialApp(
  home: M3ETheme(
    data: M3EThemeData.light(),
    child: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  testWidgets('M3EButton renders an icon-only button', _iconOnlyButton);
  testWidgets('M3EButton renders a label-only button', _labelOnlyButton);
  testWidgets('M3EButton renders icon and label together', _iconAndLabel);
  testWidgets(
    'text-style group renders icon-only and label-only actions',
    _textGroupSingleContentModes,
  );
}

Future<void> _iconOnlyButton(WidgetTester tester) async {
  await tester.pumpWidget(
    _host(
      M3EButton(
        onPressed: () {},
        icon: const Icon(M3EIcons.star),
        semanticLabel: _iconSemantic,
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.byIcon(M3EIcons.star), findsOneWidget);
  expect(find.text(_label), findsNothing);
}

Future<void> _labelOnlyButton(WidgetTester tester) async {
  await tester.pumpWidget(
    _host(M3EButton(onPressed: () {}, label: const Text(_label))),
  );
  await tester.pumpAndSettle();

  expect(find.text(_label), findsOneWidget);
  expect(find.byIcon(M3EIcons.star), findsNothing);
}

Future<void> _iconAndLabel(WidgetTester tester) async {
  // Icon after the label exercises the end-alignment swap with both parts.
  await tester.pumpWidget(
    _host(
      M3EButton(
        onPressed: () {},
        icon: const Icon(M3EIcons.star),
        label: const Text(_label),
        decoration: const M3EButtonDecoration(iconAlignment: IconAlignment.end),
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(tester.takeException(), isNull);
  expect(find.byIcon(M3EIcons.star), findsOneWidget);
  expect(find.text(_label), findsOneWidget);
  final labelRight = tester.getTopRight(find.text(_label)).dx;
  final iconLeft = tester.getTopLeft(find.byIcon(M3EIcons.star)).dx;
  expect(labelRight, lessThanOrEqualTo(iconLeft));
}

Future<void> _textGroupSingleContentModes(WidgetTester tester) async {
  await tester.pumpWidget(
    _host(
      M3EButtonGroup(
        style: M3EButtonStyle.text,
        overflow: M3EButtonGroupOverflow.none,
        actions: const <M3EButtonGroupAction>[
          M3EButtonGroupAction(
            icon: Icon(M3EIcons.star),
            semanticLabel: _iconSemantic,
          ),
          M3EButtonGroupAction(label: Text(_label)),
        ],
        onSelectedIndexChanged: (int? index) {},
      ),
    ),
  );
  await tester.pumpAndSettle();

  final visible = find.byType(M3EButton).hitTestable();
  expect(visible, findsNWidgets(2));
  expect(
    find.descendant(of: visible, matching: find.byIcon(M3EIcons.star)),
    findsOneWidget,
  );
  expect(
    find.descendant(of: visible, matching: find.text(_label)),
    findsOneWidget,
  );
}
