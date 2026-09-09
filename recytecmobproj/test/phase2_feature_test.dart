import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:recytecmobproj/core/constants/app_constants.dart';
import 'package:recytecmobproj/core/utils/map_launcher.dart';
import 'package:recytecmobproj/data/models/collected_item_model.dart';
import 'package:recytecmobproj/data/models/ewaste_detection_result.dart';
import 'package:recytecmobproj/data/repositories/notification_repository.dart';

void main() {
  group('collector status transitions', () {
    test('allows only the documented next status', () {
      expect(
        CollectorJobStatuses.canTransition(
          CollectorJobStatuses.assigned,
          CollectorJobStatuses.onTheWay,
        ),
        isTrue,
      );
      expect(
        CollectorJobStatuses.canTransition(
          CollectorJobStatuses.assigned,
          CollectorJobStatuses.completed,
        ),
        isFalse,
      );
    });

    test('normalizes legacy backend status values', () {
      expect(
        CollectorJobStatuses.normalize('In-Transit'),
        CollectorJobStatuses.onTheWay,
      );
      expect(
        CollectorJobStatuses.normalize('Approved'),
        CollectorJobStatuses.assigned,
      );
    });
  });

  group('collection report model', () {
    test('calculates quantity totals without requiring image evidence', () {
      final draft = CollectionReportDraft(
        assignmentId: 'REQ-1',
        requestReference: 'REQ-1',
        collectorName: 'Collector One',
        collectorId: 'COL-1',
      );

      expect(draft.canSubmit, isTrue);
      draft.beforeImagePath = 'before.jpg';
      draft.beforeCondition = 'Full';
      draft.afterImagePath = 'after.jpg';
      draft.finalBinStatus = 'Serviced';
      draft.items.addAll([
        CollectedEWasteItem(
          id: '1',
          imagePath: 'one.jpg',
          aiPredictedClass: 'laptop',
          aiConfidence: 0.8,
          confirmedClass: 'laptop',
          quantity: 2,
        ),
        CollectedEWasteItem(
          id: '2',
          imagePath: 'two.jpg',
          aiPredictedClass: 'battery',
          aiConfidence: 0.7,
          confirmedClass: 'battery',
          quantity: 1,
        ),
      ]);

      expect(draft.totalQuantity, 3);
      expect(draft.totalCategories, 2);
      expect(draft.canSubmit, isTrue);
      expect(draft.toJson()['totalWeightKg'], isNull);
      expect(draft.toJson()['items'].first, isNot(contains('weightKg')));
    });

    test('keeps optional total weight separate from item quantities', () {
      final draft = CollectionReportDraft(
        assignmentId: 'REQ-4',
        requestReference: 'REQ-4',
        collectorName: 'Collector One',
        totalWeightKg: 7.4,
        items: [
          CollectedEWasteItem(
            id: 'scan-1',
            imagePath: 'battery.jpg',
            aiPredictedClass: 'monitor',
            aiConfidence: 0.76,
            confirmedClass: 'battery',
            quantity: 5,
          ),
        ],
      );

      expect(draft.toJson()['totalWeightKg'], 7.4);
      expect(draft.toJson()['items'].first['detectedCategory'], 'monitor');
      expect(draft.toJson()['items'].first['confirmedCategory'], 'battery');
      expect(draft.toJson()['items'].first['wasCorrected'], isTrue);
    });

    test('accepts zero item quantity during completion validation', () {
      final draft = CollectionReportDraft(
        assignmentId: 'REQ-2',
        requestReference: 'REQ-2',
        collectorName: 'Collector One',
        beforeImagePath: 'before.jpg',
        beforeCondition: 'Full',
        afterImagePath: 'after.jpg',
        finalBinStatus: 'Serviced',
        items: [
          CollectedEWasteItem(
            id: 'bad',
            imagePath: 'bad.jpg',
            confirmedClass: 'keyboard',
            quantity: 0,
          ),
        ],
      );

      expect(draft.hasValidItems, isTrue);
      expect(draft.canSubmit, isTrue);
    });

    test('aggregates duplicate confirmed categories without losing scans', () {
      final draft = CollectionReportDraft(
        assignmentId: 'REQ-3',
        requestReference: 'REQ-3',
        collectorName: 'Collector One',
        items: [
          CollectedEWasteItem(
            id: 'scan-1',
            imagePath: 'laptop-1.jpg',
            aiPredictedClass: 'laptop',
            aiConfidence: 0.91,
            confirmedClass: 'laptop',
            quantity: 2,
          ),
          CollectedEWasteItem(
            id: 'scan-2',
            imagePath: 'laptop-2.jpg',
            aiPredictedClass: 'keyboard',
            aiConfidence: 0.44,
            confirmedClass: 'laptop',
            quantity: 2,
          ),
          CollectedEWasteItem(
            id: 'scan-3',
            imagePath: 'phone.jpg',
            aiPredictedClass: 'smartphone',
            aiConfidence: 0.88,
            confirmedClass: 'smartphone',
            quantity: 5,
          ),
        ],
      );

      expect(draft.items, hasLength(3));
      expect(draft.confirmedCategorySummary, {
        'laptop': 4,
        'smartphone': 5,
      });
      expect(draft.totalQuantity, 9);
      expect(draft.toJson()['confirmedCategorySummary']['laptop'], 4);
    });
  });

  group('role routing', () {
    test('routes household, LGU, and collector to their own shells', () {
      expect(AppRoles.shellTargetFor('Staff'), AppShellTarget.household);
      expect(AppRoles.shellTargetFor('lgu'), AppShellTarget.partnerOrg);
      expect(AppRoles.shellTargetFor('collector'), AppShellTarget.collector);
      expect(AppRoles.shellTargetFor('admin'), AppShellTarget.accessDenied);
    });
  });

  group('notification repository', () {
    test('filters notifications by role and updates read state', () async {
      final repository = NotificationRepository();
      final household = await repository.fetchNotifications(UserRole.household);

      expect(household, isNotEmpty);
      expect(
          household.every((item) => item.role == UserRole.household), isTrue);
      await repository.markAllAsRead(UserRole.household);
      expect(await repository.unreadCount(UserRole.household), 0);
    });
  });

  group('bin locator maps', () {
    test('generates directions URL from coordinates', () {
      const launcher = MapLauncher();
      final uri = launcher.googleMapsUri(
        const MapLaunchTarget(latitude: 14.1, longitude: 121.2),
      );

      expect(uri.toString(), contains('openstreetmap.org/directions'));
      expect(uri.toString(), contains('14.1%2C121.2'));
    });

    test('returns null for missing location data', () {
      const launcher = MapLauncher();
      expect(launcher.googleMapsUri(const MapLaunchTarget()), isNull);
    });
  });

  group('YOLO result mapping', () {
    test('keeps the local model label ordering unchanged', () {
      final labels = File('assets/models/labels.txt')
          .readAsLinesSync()
          .map((label) => label.trim())
          .where((label) => label.isNotEmpty)
          .toList();

      expect(labels, [
        'PCB',
        'air_conditioner',
        'battery',
        'fan',
        'keyboard',
        'laptop',
        'microwave',
        'monitor',
        'mouse',
        'oven',
        'printer',
        'refrigerator',
        'smartphone',
        'television',
        'washing_machine',
      ]);
    });

    test('stores AI prediction separately from confirmed class', () {
      final result = EWasteDetectionResult(
        detectedClass: 'smartphone',
        confidence: 0.61,
        mappedWasteCategory: 'Smartphone',
      );
      final item = CollectedEWasteItem(
        id: 'item-1',
        imagePath: 'phone.jpg',
        aiPredictedClass: result.detectedClass,
        aiConfidence: result.confidence,
        confirmedClass: 'laptop',
        quantity: 1,
      );

      expect(item.aiPredictedClass, 'smartphone');
      expect(item.confirmedClass, 'laptop');
      expect(item.mappedCategory, 'Laptop');
      expect(item.toJson()['confirmedClass'], 'laptop');
      expect(item.toJson()['aiPredictedClass'], 'smartphone');
      expect(item.toJson(), isNot(contains('weightKg')));
    });
  });
}
