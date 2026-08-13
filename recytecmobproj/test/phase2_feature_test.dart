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
    test('calculates totals and requires evidence', () {
      final draft = CollectionReportDraft(
        assignmentId: 'REQ-1',
        requestReference: 'REQ-1',
        collectorName: 'Collector One',
      );

      expect(draft.canSubmit, isFalse);
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
          weightKg: 3.5,
        ),
        CollectedEWasteItem(
          id: '2',
          imagePath: 'two.jpg',
          aiPredictedClass: 'battery',
          aiConfidence: 0.7,
          confirmedClass: 'battery',
          quantity: 1,
          weightKg: 0.5,
        ),
      ]);

      expect(draft.totalQuantity, 3);
      expect(draft.totalWeightKg, 4.0);
      expect(draft.totalCategories, 2);
      expect(draft.canSubmit, isTrue);
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

      expect(uri.toString(), contains('/maps/dir/'));
      expect(uri.toString(), contains('14.1%2C121.2'));
    });

    test('returns null for missing location data', () {
      const launcher = MapLauncher();
      expect(launcher.googleMapsUri(const MapLaunchTarget()), isNull);
    });
  });

  group('YOLO result mapping', () {
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
        weightKg: 1.2,
      );

      expect(item.aiPredictedClass, 'smartphone');
      expect(item.confirmedClass, 'laptop');
      expect(item.mappedCategory, 'Laptop');
    });
  });
}
