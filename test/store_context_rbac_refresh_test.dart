import 'package:flutter_test/flutter_test.dart';
import 'package:bokrah_retail/app/features/store/data/models/store_dto.dart';
import 'package:bokrah_retail/app/features/store/data/models/store_entity.dart';
import 'package:bokrah_retail/app/features/store/data/models/store_rbac_models.dart';
import 'package:bokrah_retail/app/features/store/data/services/store_api_service.dart';
import 'package:bokrah_retail/app/features/store/data/services/store_service.dart';
import 'package:bokrah_retail/app/features/store/presentation/cubits/store_cubit.dart';
import 'package:bokrah_retail/app/features/store/presentation/cubits/store_state.dart';
import 'package:bokrah_retail/app/features/store/presentation/cubits/store_rbac_cubit.dart';

class MultiStoreTestApiService implements StoreApiService {
  final Map<int, List<StoreMemberDto>> storeMembersMap = {};
  final Map<int, List<StoreRoleDto>> storeRolesMap = {};

  @override
  Future<List<StoreResponseDto>> getMyStores() async => [
        const StoreResponseDto(
          id: 10,
          ownerUserId: 1,
          name: 'Main Amman Branch',
          currencyCode: 'JOD',
          isActive: true,
          currentUserRole: 'Owner',
          createdAtUtc: '2026-11-19T17:00:00Z',
        ),
        const StoreResponseDto(
          id: 20,
          ownerUserId: 99,
          name: 'Irbid Branch',
          currencyCode: 'JOD',
          isActive: true,
          currentUserRole: 'Member',
          createdAtUtc: '2026-11-19T17:00:00Z',
        ),
      ];

  @override
  Future<StoreResponseDto> getStoreById(int storeId) async {
    if (storeId == 10) {
      return const StoreResponseDto(
        id: 10,
        ownerUserId: 1,
        name: 'Main Amman Branch',
        currencyCode: 'JOD',
        isActive: true,
        currentUserRole: 'Owner',
        createdAtUtc: '2026-11-19T17:00:00Z',
      );
    }
    return const StoreResponseDto(
      id: 20,
      ownerUserId: 99,
      name: 'Irbid Branch',
      currencyCode: 'JOD',
      isActive: true,
      currentUserRole: 'Member',
      createdAtUtc: '2026-11-19T17:00:00Z',
    );
  }

  @override
  Future<List<StorePermissionDto>> getPermissionCatalog() async => [
        const StorePermissionDto(
          code: 'store.roles.manage',
          name: 'Manage Roles',
          description: 'Manage roles',
          category: 'Roles',
        ),
        const StorePermissionDto(
          code: 'store.orders.view',
          name: 'View Orders',
          description: 'View orders',
          category: 'Orders',
        ),
      ];

  @override
  Future<List<StoreRoleDto>> getStoreRoles(int storeId) async =>
      storeRolesMap[storeId] ?? [];

  @override
  Future<List<StoreMemberDto>> getStoreMembers(int storeId) async =>
      storeMembersMap[storeId] ?? [];

  @override
  Future<StoreRoleDto> createStoreRole(
    int storeId,
    CreateStoreRoleRequest request,
  ) =>
      throw UnimplementedError();

  @override
  Future<StoreRoleDto> updateStoreRole(
    int storeId,
    int roleId,
    UpdateStoreRoleRequest request,
  ) =>
      throw UnimplementedError();

  @override
  Future<void> deleteStoreRole(int storeId, int roleId) =>
      throw UnimplementedError();

  @override
  Future<StoreMemberDto> provisionMember(
    int storeId,
    ProvisionStoreMemberRequest request,
  ) =>
      throw UnimplementedError();

  @override
  Future<StoreMemberDto> addMember(
    int storeId,
    AddStoreMemberRequest request,
  ) =>
      throw UnimplementedError();

  @override
  Future<StoreMemberDto> updateMemberRoles(
    int storeId,
    int userId,
    UpdateMemberRolesRequest request,
  ) =>
      throw UnimplementedError();

  @override
  Future<void> removeMember(int storeId, int userId) =>
      throw UnimplementedError();

  @override
  Future<StoreResponseDto> createStore(CreateStoreRequest request) =>
      throw UnimplementedError();
}

class FakeStoreService extends StoreService {
  int? _activeId;
  StoreEntity _info = const StoreEntity(id: '10', nameAr: 'Main', nameEn: 'Main');

  @override
  Future<StoreEntity> getStoreInfo() async => _info;

  @override
  Future<bool> updateStoreInfo(StoreEntity info) async {
    _info = info;
    return true;
  }

  @override
  Future<int?> getActiveStoreId() async => _activeId;

  @override
  Future<void> setActiveStoreId(int id) async {
    _activeId = id;
  }

  @override
  Future<bool> hasRegisteredStore([String? key]) async => true;

  @override
  Future<List<StoreEntity>> getCachedAccessibleStores() async => [];

  @override
  Future<void> cacheAccessibleStores(List<StoreEntity> stores) async {}
}

void main() {
  test('Switching active store context dynamically reloads RBAC permissions',
      () async {
    final fakeApi = MultiStoreTestApiService();
    fakeApi.storeMembersMap[10] = [
      StoreMemberDto(
        storeId: 10,
        userId: 1,
        userEmail: 'operator@bokrah.com',
        userFullName: 'Operator 1',
        role: 'Owner',
        customRoleIds: const [],
        customRoles: const [],
        effectivePermissions: const ['store.roles.manage', 'store.orders.view'],
        createdAtUtc: DateTime.now().toUtc(),
      )
    ];

    fakeApi.storeMembersMap[20] = [
      StoreMemberDto(
        storeId: 20,
        userId: 1,
        userEmail: 'operator@bokrah.com',
        userFullName: 'Operator 1',
        role: 'Member',
        customRoleIds: const [102],
        customRoles: const ['Cashier'],
        effectivePermissions: const ['store.orders.view'],
        createdAtUtc: DateTime.now().toUtc(),
      )
    ];

    final rbacCubit = StoreRbacCubit(apiService: fakeApi);
    final storeService = FakeStoreService();
    final storeCubit = StoreCubit(
      service: storeService,
      apiService: fakeApi,
      rbacCubit: rbacCubit,
    );

    // Initial load: Store 10 (Owner)
    await storeCubit.loadStore();
    await rbacCubit.loadStoreRbacContext(10, currentUserId: 1);

    final loaded10 = storeCubit.state as StoreLoaded;
    expect(loaded10.store.id, equals('10'));
    expect(rbacCubit.state.isCurrentMemberOwner, isTrue);
    expect(rbacCubit.state.can('store.roles.manage'), isTrue);

    // Switch store to Store 20 (Member only, with only store.orders.view)
    final switched = await storeCubit.switchActiveStore(20);
    expect(switched, isTrue);

    final loaded20 = storeCubit.state as StoreLoaded;
    expect(loaded20.activeStoreId, equals(20));

    // Wait for rbac context to reflect Store 20
    await rbacCubit.loadStoreRbacContext(20, currentUserId: 1);

    expect(rbacCubit.state.isCurrentMemberOwner, isFalse);
    expect(rbacCubit.state.can('store.orders.view'), isTrue);
    expect(rbacCubit.state.can('store.roles.manage'), isFalse);
  });
}
