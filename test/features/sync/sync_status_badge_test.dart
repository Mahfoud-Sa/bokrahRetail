import 'package:bokrah_retail/app/features/sync/domain/entities/sync_conflict.dart';
import 'package:bokrah_retail/app/features/sync/domain/entities/sync_operation.dart';
import 'package:bokrah_retail/app/features/sync/presentation/cubits/sync_state.dart';
import 'package:bokrah_retail/app/features/sync/presentation/widgets/sync_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SyncStatusBadge renders all sync phases and handles tap',
      (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SyncStatusBadge(
            syncState: const SyncState(phase: SyncPhase.synced),
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('متزامن'), findsOneWidget);
    await tester.tap(find.byType(SyncStatusBadge));
    expect(tapped, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SyncStatusBadge(
            syncState: SyncState(
              phase: SyncPhase.conflict,
              conflicts: [
                SyncConflict(
                  operationId: 'op1',
                  storeId: 1,
                  entityType: SyncEntityType.item,
                  localEntityId: 1,
                  localPayload: const {},
                  serverPayload: const {},
                  detectedAt: DateTime(2026),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('تعارض (1)'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SyncStatusBadge(
            syncState: SyncState(phase: SyncPhase.guestReadOnly),
          ),
        ),
      ),
    );

    expect(find.text('وضع الضيف'), findsOneWidget);
  });
}
