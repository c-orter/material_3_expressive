import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/components/bottom_sheets/components/m3e_bottom_sheet_surface.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

final M3EThemeData _theme = M3EThemeData.light(
  seedColor: const Color(0xFF6750A4),
);

final Finder _surface = find.byType(M3EBottomSheetSurface);

void main() {
  setUp(M3EFocusInteraction.resetForTest);
  testWidgets('predictive back shrinks the sheet', _predictiveBack);
  testWidgets(
    'predictive back still previews through the dismiss guard',
    _backWithGuard,
  );
  testWidgets('predictive back keeps the inner list alive', _backKeepsScroll);
  testWidgets('predictive back exit keeps the scale steady', _backExitSteady);
}

Future<BuildContext> _pump(
  WidgetTester tester,
  Size size, {
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
        home: Builder(
          builder: (BuildContext context) {
            captured = context;
            return const SizedBox.expand();
          },
        ),
      ),
    ),
  );
  return captured;
}

Widget _longList(BuildContext context) {
  return ListView(
    children: <Widget>[
      for (var i = 0; i < 60; i++) SizedBox(height: 48, child: Text('Row $i')),
    ],
  );
}

Widget _short(BuildContext context) =>
    const SizedBox(height: 100, child: Text('Short'));

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

Map<String, dynamic> _backArgs(double progress) => <String, dynamic>{
  'touchOffset': <double>[5, 600],
  'progress': progress,
  'swipeEdge': 0,
};

double _sheetScaleY(WidgetTester tester) {
  final Transform transform = tester.widget<Transform>(
    find.ancestor(of: _surface, matching: find.byType(Transform)).first,
  );
  return transform.transform.storage[5];
}

Future<void> _predictiveBack(WidgetTester tester) async {
  final BuildContext context = await _pump(tester, const Size(400, 800));
  var closed = false;
  M3EBottomSheet.show<void>(
    context,
    builder: _short,
  ).then((_) => closed = true);
  await tester.pumpAndSettle();

  await _sendBack(tester, 'startBackGesture', _backArgs(0));
  await _sendBack(tester, 'updateBackGestureProgress', _backArgs(1));
  await tester.pump();
  final Transform transform = tester.widget<Transform>(
    find.ancestor(of: _surface, matching: find.byType(Transform)).first,
  );
  expect(transform.transform.storage[0], closeTo(1 - 48 / 400, 0.001));
  await _sendBack(tester, 'commitBackGesture');
  await tester.pumpAndSettle();
  expect(closed, isTrue);
}

Future<void> _backWithGuard(WidgetTester tester) async {
  final BuildContext context = await _pump(tester, const Size(400, 800));
  var allow = false;
  var closed = false;
  M3EBottomSheet.show<void>(
    context,
    builder: _short,
    onDismissRequest: () async => allow,
  ).then((_) => closed = true);
  await tester.pumpAndSettle();
  final double height = tester.getSize(_surface).height;

  await _sendBack(tester, 'startBackGesture', _backArgs(0));
  await _sendBack(tester, 'updateBackGestureProgress', _backArgs(1));
  await tester.pump();
  expect(
    _sheetScaleY(tester),
    closeTo(1 - 24 / height, 0.001),
    reason: 'a guarded sheet must still preview the predictive back gesture',
  );

  await _sendBack(tester, 'commitBackGesture');
  await tester.pumpAndSettle();
  expect(closed, isFalse, reason: 'a rejected guard keeps the sheet open');
  expect(
    _sheetScaleY(tester),
    closeTo(1, 0.001),
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
  final BuildContext context = await _pump(tester, const Size(400, 800));
  M3EBottomSheet.show<void>(
    context,
    initialValue: M3EBottomSheetValue.expanded,
    builder: _longList,
  );
  await tester.pumpAndSettle();
  await tester.drag(find.text('Row 2'), const Offset(0, -200));
  await tester.pumpAndSettle();
  final ScrollableState scrollable = tester.state<ScrollableState>(
    find.byType(Scrollable),
  );
  expect(scrollable.position.pixels, greaterThan(0), reason: 'list scrolled');

  await _sendBack(tester, 'startBackGesture', _backArgs(0));
  await _sendBack(tester, 'updateBackGestureProgress', _backArgs(0.5));
  await tester.pump();
  expect(
    identical(
      scrollable,
      tester.state<ScrollableState>(find.byType(Scrollable)),
    ),
    isTrue,
    reason: 'the back drag must keep the sheet content alive',
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
    reason: 'the cancelled settle must keep the sheet content alive',
  );
  expect(
    tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
    scrollable.position.pixels,
  );
}

Future<void> _backExitSteady(WidgetTester tester) async {
  final BuildContext context = await _pump(tester, const Size(400, 800));
  var closed = false;
  M3EBottomSheet.show<void>(
    context,
    initialValue: M3EBottomSheetValue.expanded,
    builder: _longList,
  ).then((_) => closed = true);
  await tester.pumpAndSettle();

  await _sendBack(tester, 'startBackGesture', _backArgs(0));
  await _sendBack(tester, 'updateBackGestureProgress', _backArgs(1));
  await tester.pump();
  final double scaleY = _sheetScaleY(tester);
  await _sendBack(tester, 'commitBackGesture');
  for (var i = 0; i < 30 && _surface.evaluate().isNotEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    if (_surface.evaluate().isEmpty) {
      break;
    }
    expect(
      _sheetScaleY(tester),
      closeTo(scaleY, 0.0001),
      reason: 'the scale must stay put while the sheet exits (frame $i)',
    );
  }
  await tester.pumpAndSettle();
  expect(closed, isTrue);
}
