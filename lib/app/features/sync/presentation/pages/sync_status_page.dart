import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/core/widgets/widgets.dart';
import 'package:bokrah_retail/app/features/sync/domain/entities/sync_conflict.dart';
import 'package:bokrah_retail/app/features/sync/presentation/cubits/sync_cubit.dart';
import 'package:bokrah_retail/app/features/sync/presentation/cubits/sync_state.dart';
import 'package:bokrah_retail/app/features/sync/presentation/widgets/sync_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Displays store synchronization status, outbox queue, and conflict resolution.
class SyncStatusPage extends StatelessWidget {
  const SyncStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.mainBackground,
        appBar: AppBar(
          title: const Text('مزامنة بيانات المتجر'),
          backgroundColor: AppTheme.deepCobalt,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: BlocBuilder<SyncCubit, SyncState>(
          builder: (context, state) {
            final cubit = context.read<SyncCubit>();
            final isGuest = state.phase == SyncPhase.guestReadOnly;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FormSectionCard(
                        title: 'حالة المزامنة الحالية',
                        icon: Icons.sync,
                        trailing: SyncStatusBadge(syncState: state),
                        children: [
                          if (state.lastSyncedAt != null)
                            Text(
                              'آخر مزامنة: ${state.lastSyncedAt!.toLocal()}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.secondaryText,
                              ),
                            )
                          else
                            const Text(
                              'لم تتم المزامنة بعد في هذه الجلسة.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.secondaryText,
                              ),
                            ),
                          if (state.lastError != null &&
                              state.lastError!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.errorSurface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: AppTheme.error,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      state.lastError!,
                                      style: const TextStyle(
                                        color: AppTheme.error,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              FilledButton.icon(
                                onPressed: isGuest ||
                                        state.phase == SyncPhase.syncing
                                    ? null
                                    : () => cubit.syncNow(),
                                icon: const Icon(Icons.sync, size: 18),
                                label: const Text('مزامنة الآن'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.actionBlue,
                                ),
                              ),
                              if (state.failedCount > 0)
                                OutlinedButton.icon(
                                  onPressed: isGuest
                                      ? null
                                      : () => cubit.retryFailed(),
                                  icon: const Icon(Icons.refresh, size: 18),
                                  label: Text(
                                    'إعادة محاولة الفاشلة (${state.failedCount})',
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (state.conflicts.isNotEmpty) ...[
                        FormSectionCard(
                          title: 'تعارضات المزامنة (${state.conflictCount})',
                          icon: Icons.warning_amber_rounded,
                          children: state.conflicts
                              .map(
                                (conflict) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.subtleSurface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppTheme.warmOrange
                                            .withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${conflict.entityType.wireName} #${conflict.localEntityId}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          conflict.reason,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.secondaryText,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            OutlinedButton(
                                              onPressed: () =>
                                                  cubit.resolveConflict(
                                                conflict.operationId,
                                                ConflictResolutionStrategy
                                                    .serverWins,
                                              ),
                                              child: const Text(
                                                'اعتماد نسخة الخادم',
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            FilledButton(
                                              onPressed: () =>
                                                  cubit.resolveConflict(
                                                conflict.operationId,
                                                ConflictResolutionStrategy
                                                    .clientWins,
                                              ),
                                              style: FilledButton.styleFrom(
                                                backgroundColor:
                                                    AppTheme.warmOrange,
                                              ),
                                              child: const Text(
                                                'اعتماد نسختي المحلية',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                      FormSectionCard(
                        title:
                            'العمليات المعلقة في قائمة الانتظار (${state.pendingCount})',
                        icon: Icons.queue_outlined,
                        children: [
                          if (state.pendingOperations.isEmpty)
                            const Text(
                              'لا توجد عمليات معلقة. جميع البيانات المحلية متزامنة.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.secondaryText,
                              ),
                            )
                          else
                            ...state.pendingOperations.map(
                              (op) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  op.operationType.name == 'delete'
                                      ? Icons.delete_outline
                                      : Icons.cloud_upload_outlined,
                                  color: AppTheme.actionBlue,
                                ),
                                title: Text(
                                  '${op.entityType.wireName} • ${op.operationType.name} (#${op.localEntityId})',
                                ),
                                subtitle: op.lastError != null
                                    ? Text(
                                        op.lastError!,
                                        style: const TextStyle(
                                          color: AppTheme.error,
                                          fontSize: 11,
                                        ),
                                      )
                                    : Text(
                                        'الحالة: ${op.status.name}',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
