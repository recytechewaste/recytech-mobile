import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recytecmobproj/core/theme/recytechtheme.dart';
import 'package:recytecmobproj/widgets/empty_state.dart';
import 'package:recytecmobproj/widgets/status_bagde.dart';

void main() {
  testWidgets('shared empty and error states expose clear accessible actions',
      (tester) async {
    var retries = 0;

    await tester.pumpWidget(_app(
      AppErrorState(
        title: 'Unable to load information. Please try again.',
        onRetry: () async => retries++,
      ),
    ));

    expect(
      find.text('Unable to load information. Please try again.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(retries, 1);
  });

  testWidgets('status badges distinguish successful and unavailable states',
      (tester) async {
    await tester.pumpWidget(_app(
      const Scaffold(
        body: Column(
          children: [
            StatusBadge(label: 'Active'),
            StatusBadge(label: 'Offline'),
            StatusBadge(label: 'In Progress'),
          ],
        ),
      ),
    ));

    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
    expect(find.text('In Progress'), findsOneWidget);
  });

  test('presentation copy preserves map and quantity-only workflow contracts',
      () {
    final locator = File(
      'lib/presentation/user/bins/bin_locator_screen.dart',
    ).readAsStringSync();
    final workflow = File(
      'lib/presentation/collector/collection/collection_workflow_screen.dart',
    ).readAsStringSync();
    final collectorHistory = File(
      'lib/presentation/collector/history/collector_history_screen.dart',
    ).readAsStringSync();
    final partnerTracking = File(
      'lib/presentation/lgu/requests/collection_request_tracking_screen.dart',
    ).readAsStringSync();

    expect(locator, contains('View location on map'));
    expect(locator, isNot(contains("Text('Directions')")));
    expect(workflow, isNot(contains('Optional Weight')));
    expect(workflow, isNot(contains('_totalWeightKg')));
    expect(workflow, isNot(contains("'Total weight'")));
    expect(collectorHistory.toLowerCase(), isNot(contains('total weight')));
    expect(partnerTracking.toLowerCase(), isNot(contains("'weight'")));
  });
}

Widget _app(Widget home) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (_, __) => MaterialApp(
      theme: RecyTechTheme.light(),
      home: home,
    ),
  );
}
