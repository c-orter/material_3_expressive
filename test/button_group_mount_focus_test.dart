import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import 'mount_focus_test_support.dart';

void main() {
  testWidgets('button group does not take focus on mount', (tester) async {
    await expectMountKeepsFocus(
      tester,
      () => const M3EButtonGroup(
        actions: <M3EButtonGroupAction>[
          M3EButtonGroupAction(label: Text('A')),
          M3EButtonGroupAction(label: Text('B')),
        ],
      ),
    );
  });
}
