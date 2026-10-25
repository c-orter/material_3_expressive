import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import 'mount_focus_test_support.dart';

void main() {
  testWidgets('segmented button does not take focus on mount', (tester) async {
    await expectMountKeepsFocus(
      tester,
      () => M3ESegmentedButton<int>(
        selected: const <int>{0},
        onSelectionChanged: (_) {},
        segments: const <M3ESegment<int>>[
          M3ESegment<int>(value: 0, label: 'A'),
          M3ESegment<int>(value: 1, label: 'B'),
        ],
      ),
    );
  });
}
