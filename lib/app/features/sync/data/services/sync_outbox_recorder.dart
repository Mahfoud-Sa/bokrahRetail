import 'package:bokrah_retail/app/features/auth/data/datasources/auth_token_storage.dart';
import 'package:bokrah_retail/app/features/store/data/services/store_service.dart';
import 'package:bokrah_retail/app/features/sync/domain/entities/sync_operation.dart';
import 'package:bokrah_retail/app/features/sync/domain/repositories/sync_repository.dart';
import 'package:bokrah_retail/app/initialzation_dependencies.dart';

/// Records local catalog mutations into the active Store's outbox.
///
/// Safe to call from any repository or service:
/// - No-ops in Guest mode or when no active Store is selected.
/// - Generates a deterministic-style unique idempotency key per mutation.
class SyncOutboxRecorder {
  final SyncRepository? _syncRepository;
  final AuthTokenStorage? _tokenStorage;
  final StoreService? _storeService;
  final void Function(int storeId)? onOperationEnqueued;

  int _sequence = 0;

  SyncOutboxRecorder({
    SyncRepository? syncRepository,
    AuthTokenStorage? tokenStorage,
    StoreService? storeService,
    this.onOperationEnqueued,
  })  : _syncRepository = syncRepository,
        _tokenStorage = tokenStorage,
        _storeService = storeService;

  /// Resolves dependencies lazily from [singelton] if not explicitly injected.
  SyncRepository? get _repo =>
      _syncRepository ??
      (singelton.isRegistered<SyncRepository>()
          ? singelton<SyncRepository>()
          : null);

  AuthTokenStorage? get _auth =>
      _tokenStorage ??
      (singelton.isRegistered<AuthTokenStorage>()
          ? singelton<AuthTokenStorage>()
          : null);

  StoreService? get _store =>
      _storeService ??
      (singelton.isRegistered<StoreService>()
          ? singelton<StoreService>()
          : null);

  Future<void> record({
    required SyncEntityType entityType,
    required SyncOperationType operationType,
    required int localEntityId,
    Map<String, dynamic> payload = const {},
  }) async {
    final repo = _repo;
    final auth = _auth;
    final store = _store;
    if (repo == null || auth == null || store == null) return;

    // Guest mode / unauthenticated sessions must remain read-only for sync.
    final session = await auth.getSession();
    if (session == null || session.accessToken.trim().isEmpty) return;

    final storeId = await store.getActiveStoreId();
    if (storeId == null) return;

    final now = DateTime.now();
    _sequence++;
    final opId =
        '${entityType.wireName}_${localEntityId}_${now.microsecondsSinceEpoch}_$_sequence';

    await repo.enqueueOperation(
      SyncOperation(
        id: opId,
        idempotencyKey: opId,
        storeId: storeId,
        entityType: entityType,
        operationType: operationType,
        localEntityId: localEntityId,
        payload: payload,
        createdAt: now,
        updatedAt: now,
      ),
    );

    onOperationEnqueued?.call(storeId);
  }
}
