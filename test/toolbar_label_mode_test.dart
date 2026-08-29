import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

Widget _host({required Widget child}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: M3ETheme(
      data: M3EThemeData.light(seedColor: const Color(0xFF6750A4)),
      child: Overlay(
        initialEntries: [OverlayEntry(builder: (_) => Center(child: child))],
      ),
    ),
  );
}

List<M3EToolbarItem> _labeledActions() => <M3EToolbarItem>[
  M3EToolbarAction(
    icon: M3EIcons.edit,
    label: 'One',
    active: true,
    onPressed: () {},
  ),
  M3EToolbarAction(icon: M3EIcons.share, label: 'Two', onPressed: () {}),
  M3EToolbarAction(icon: M3EIcons.settings, label: 'Three', onPressed: () {}),
];

void main() {
  testWidgets('selectedIcon mode shows the icon only on the active action', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        child: M3EToolbar(
          labelMode: M3EToolbarLabelMode.selectedIcon,
          actions: _labeledActions(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // All three labels are visible; only the active action's icon renders.
    expect(find.text('One'), findsOneWidget);
    expect(find.text('Two'), findsOneWidget);
    expect(find.text('Three'), findsOneWidget);
    expect(find.byIcon(M3EIcons.edit), findsOneWidget);
    expect(find.byIcon(M3EIcons.share), findsNothing);
    expect(find.byIcon(M3EIcons.settings), findsNothing);
  });

  testWidgets('always mode shows icon and label on every action', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        child: M3EToolbar(
          labelMode: M3EToolbarLabelMode.always,
          actions: _labeledActions(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('One'), findsOneWidget);
    expect(find.text('Two'), findsOneWidget);
    expect(find.text('Three'), findsOneWidget);
    expect(find.byIcon(M3EIcons.edit), findsOneWidget);
    expect(find.byIcon(M3EIcons.share), findsOneWidget);
    expect(find.byIcon(M3EIcons.settings), findsOneWidget);
  });

  testWidgets('activeOnly mode shows the label only on the active action', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(child: M3EToolbar(actions: _labeledActions())),
    );
    await tester.pumpAndSettle();

    expect(find.text('One'), findsOneWidget);
    expect(find.text('Two'), findsNothing);
    expect(find.text('Three'), findsNothing);
    expect(find.byIcon(M3EIcons.edit), findsOneWidget);
    expect(find.byIcon(M3EIcons.share), findsOneWidget);
    expect(find.byIcon(M3EIcons.settings), findsOneWidget);
  });

  testWidgets('active action label uses the button foreground (onPrimary)', (
    tester,
  ) async {
    final Color onPrimary = M3EThemeData.light(
      seedColor: const Color(0xFF6750A4),
    ).colorScheme.onPrimary;

    await tester.pumpWidget(
      _host(
        child: M3EToolbar(
          labelMode: M3EToolbarLabelMode.selectedIcon,
          actions: _labeledActions(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Text activeLabel = tester.widget<Text>(find.text('One'));
    expect(activeLabel.style?.color, onPrimary);
  });
}
