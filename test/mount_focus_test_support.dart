import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

/// Mounts `child` in a second [FocusScope] while the first scope owns focus.
/// Official M3 components never take focus on mount.
Future<void> expectMountKeepsFocus(
  WidgetTester tester,
  Widget Function() child,
) async {
  final before = FocusNode(debugLabel: 'before');
  addTearDown(before.dispose);
  var show = false;
  late StateSetter setHostState;

  await tester.pumpWidget(
    MaterialApp(
      home: M3ETheme(
        data: M3EThemeData.light(),
        child: Scaffold(
          body: Column(
            children: <Widget>[
              FocusScope(
                child: Focus(
                  focusNode: before,
                  child: const SizedBox(width: 10, height: 10),
                ),
              ),
              FocusScope(
                child: StatefulBuilder(
                  builder: (context, setState) {
                    setHostState = setState;
                    return show
                        ? child()
                        : const SizedBox(width: 10, height: 10);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  before.requestFocus();
  await tester.pump();
  expect(before.hasPrimaryFocus, isTrue);

  setHostState(() => show = true);
  await tester.pump();

  expect(before.hasPrimaryFocus, isTrue);
}
