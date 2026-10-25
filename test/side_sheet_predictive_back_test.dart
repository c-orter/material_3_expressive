import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/components/side_sheets/components/m3e_side_sheet_surface.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

final M3EThemeData _theme = M3EThemeData.light(
  seedColor: const Color(0xFF6750A4),
);

final Finder _surface = find.byType(M3ESideSheetSurface);

void main() {
  setUp(M3EFocusInteraction.resetForTest);
  testWidgets('predictive back lifts, scales and commits', _predictiveBack);
  testWidgets('predictive back cancel springs back', _predictiveCancel);
  testWidgets(
    'predictive back still previews through the dismiss guard',
    _backWithGuard,
  );
  testWidgets(
    'predictive back keeps the body scroll position',
    _backKeepsScroll,
  );
}

Future<BuildContext> _pump(
  WidgetTester tester, {
  Size size = const Size(400, 800),
  TextDirection direction = TextDirection.ltr,
  Widget? home,
  M3EThemeData? theme,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late BuildContext captured;
  await tester.pumpWidget(
    M3ETheme(
      data: theme ?? _theme,
      child: MaterialApp(
        // Edge-to-edge apps strip the bottom inset from MediaQuery.
        builder: (BuildContext context, Widget? child) =>
            MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: Directionality(textDirection: direction, child: child!),
            ),
        home: Builder(
          builder: (BuildContext context) {
            captured = context;
            return home ?? const SizedBox.expand();
          },
        ),
      ),
    ),
  );
  return captured;
}

Future<Future<Object?>> _show(
  WidgetTester tester,
  BuildContext context, {
  List<Widget> actions = const <Widget>[],
  bool detached = false,
  double? width,
  Future<bool> Function()? onDismissRequest,
  M3ESideSheetController? controller,
}) async {
  final Future<Object?> result = M3ESideSheet.show<Object?>(
    context,
    title: 'Filters',
    body: const Text('Body'),
    actions: actions,
    detached: detached,
    width: width,
    onDismissRequest: onDismissRequest,
    controller: controller,
  );
  await tester.pumpAndSettle();
  return result;
}

BoxDecoration _decoration(WidgetTester tester) {
  final DecoratedBox box = tester.widget<DecoratedBox>(
    find.descendant(of: _surface, matching: find.byType(DecoratedBox)).first,
  );
  return box.decoration as BoxDecoration;
}

Future<void> _sendBack(
  WidgetTester tester,
  String method, [
  Map<String, dynamic>? args,
]) async {
  final ByteData data = const StandardMethodCodec().encodeMethodCall(
    MethodCall(method, args),
  );
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.backGesture.name,
    data,
    (ByteData? _) {},
  );
}

Map<String, dynamic> _backArgs(double progress, {int edge = 0}) =>
    <String, dynamic>{
      'touchOffset': <double>[5, 400],
      'progress': progress,
      'swipeEdge': edge,
    };

Future<void> _predictiveBack(WidgetTester tester) async {
  final BuildContext context = await _pump(tester);
  var closed = false;
  (await _show(tester, context)).then((_) => closed = true);
  await _sendBack(tester, 'startBackGesture', _backArgs(0));
  await _sendBack(tester, 'updateBackGestureProgress', _backArgs(1));
  await tester.pump();
  final Transform transform = tester.widget<Transform>(
    find.ancestor(of: _surface, matching: find.byType(Transform)).first,
  );
  final m = transform.transform.storage;
  expect(m[0], closeTo(1 - 24 / 256, 0.001), reason: 'shrinks from left');
  expect(m[5], closeTo(1 - 48 / 800, 0.001), reason: 'lifts off edges');
  expect(_decoration(tester).borderRadius, BorderRadius.circular(16));
  await _sendBack(tester, 'commitBackGesture');
  await tester.pumpAndSettle();
  expect(closed, isTrue);
}

Future<void> _predictiveCancel(WidgetTester tester) async {
  final BuildContext context = await _pump(tester);
  await _show(tester, context);
  await _sendBack(tester, 'startBackGesture', _backArgs(0, edge: 1));
  await _sendBack(tester, 'updateBackGestureProgress', _backArgs(1, edge: 1));
  await tester.pump();
  final Transform grow = tester.widget<Transform>(
    find.ancestor(of: _surface, matching: find.byType(Transform)).first,
  );
  expect(grow.transform.storage[0], closeTo(1 + 12 / 256, 0.001));
  await _sendBack(tester, 'cancelBackGesture');
  await tester.pumpAndSettle();
  expect(_surface, findsOneWidget);
  expect(tester.getRect(_surface).width, 256);
}

Future<void> _backWithGuard(WidgetTester tester) async {
  final BuildContext context = await _pump(tester);
  var allow = false;
  var closed = false;
  (await _show(
    tester,
    context,
    onDismissRequest: () async => allow,
  )).then((_) => closed = true);

  await _sendBack(tester, 'startBackGesture', _backArgs(0));
  await _sendBack(tester, 'updateBackGestureProgress', _backArgs(1));
  await tester.pump();
  final Transform shrink = tester.widget<Transform>(
    find.ancestor(of: _surface, matching: find.byType(Transform)).first,
  );
  expect(
    shrink.transform.storage[0],
    closeTo(1 - 24 / 256, 0.001),
    reason: 'a guarded sheet must still preview the predictive back gesture',
  );

  await _sendBack(tester, 'commitBackGesture');
  await tester.pumpAndSettle();
  expect(closed, isFalse, reason: 'a rejected guard keeps the sheet open');
  expect(_surface, findsOneWidget);
  expect(
    tester.getRect(_surface).width,
    256,
    reason: 'a rejected preview settles the sheet back to rest',
  );

  allow = true;
  await _sendBack(tester, 'startBackGesture', _backArgs(0));
  await _sendBack(tester, 'updateBackGestureProgress', _backArgs(1));
  await tester.pump();
  await _sendBack(tester, 'commitBackGesture');
  await tester.pumpAndSettle();
  expect(closed, isTrue, reason: 'an allowed guard closes the sheet');
}

Future<void> _backKeepsScroll(WidgetTester tester) async {
  final BuildContext context = await _pump(tester);
  M3ESideSheet.show<void>(
    context,
    title: 'Filters',
    scrollable: true,
    body: Column(
      children: <Widget>[
        for (var i = 0; i < 40; i++) SizedBox(height: 48, child: Text('R$i')),
      ],
    ),
  );
  await tester.pumpAndSettle();
  final ScrollableState scrollable = tester.state<ScrollableState>(
    find.byType(Scrollable),
  );
  await tester.drag(find.text('R3'), const Offset(-100, -300));
  await tester.pumpAndSettle();
  expect(scrollable.position.pixels, greaterThan(0), reason: 'body scrolled');

  await _sendBack(tester, 'startBackGesture', _backArgs(0));
  await _sendBack(tester, 'updateBackGestureProgress', _backArgs(0.5));
  await tester.pump();
  expect(
    identical(
      scrollable,
      tester.state<ScrollableState>(find.byType(Scrollable)),
    ),
    isTrue,
    reason: 'the back drag must keep the sheet body alive',
  );
  expect(
    tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
    scrollable.position.pixels,
  );

  await _sendBack(tester, 'cancelBackGesture');
  await tester.pumpAndSettle();
  expect(
    identical(
      scrollable,
      tester.state<ScrollableState>(find.byType(Scrollable)),
    ),
    isTrue,
    reason: 'the cancelled settle must keep the sheet body alive',
  );
  expect(
    tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
    scrollable.position.pixels,
  );
}
