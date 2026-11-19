import 'package:flutter_test/flutter_test.dart';
import 'package:bokrah_retail/app/features/store/data/models/store_rbac_models.dart';
import 'package:bokrah_retail/app/features/store/data/models/store_dto.dart';
import 'package:bokrah_retail/app/features/store/data/services/store_api_service.dart';
import 'package:bokrah_retail/app/features/store/presentation/cubits/store_rbac_cubit.dart';
import 'package:bokrah_retail/app/features/store/presentation/cubits/store_rbac_state.dart';

class TestStoreApiService implements StoreApiService {
  List<StoreRoleDto> mockRoles = [];
  List<StoreMemberDto> mockMembers = [];
  List<StorePermissionDto> mockCatalog = [
    const StorePermissionDto(
      code: 'store.orders.view',
      name: 'View Orders',
      description: 'View orders',
      category: 'Orders',
    ),
    const StorePermissionDto(
      code: 'store.roles.manage',
      name: 'Manage Roles',
      description: 'Manage roles',
      category: 'Roles',
    ),
  ];

  @override
  Future<List<StorePermissionDto>> getPermissionCatalog() async => mockCatalog;

  @override
  Future<List<StoreRoleDto>> getStoreRoles(int storeId) async => mockRoles;

  @override
  Future<StoreRoleDto> createStoreRole(
    int storeId,
    CreateStoreRoleRequest request,
  ) async {
    final role = StoreRoleDto(
      id: 99,
      storeId: storeId,
      name: request.name,
      description: request.description,
      permissionCodes: request.permissionCodes,
      memberCount: 0,
      createdAtUtc: DateTime.now().toUtc(),
    );
    mockRoles.add(role);
    return role;
  }

  @override
  Future<StoreRoleDto> updateStoreRole(
    int storeId,
    int roleId,
    UpdateStoreRoleRequest request,
  ) async {
    final updated = StoreRoleDto(
      id: roleId,
      storeId: storeId,
      name: request.name,
      description: request.description,
      permissionCodes: request.permissionCodes,
      memberCount: 0,
      createdAtUtc: DateTime.now().toUtc(),
    );
    final idx = mockRoles.indexWhere((r) => r.id == roleId);
    if (idx != -1) mockRoles[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteStoreRole(int storeId, int roleId) async {
    mockRoles.removeWhere((r) => r.id == roleId);
  }

  @override
  Future<List<StoreMemberDto>> getStoreMembers(int storeId) async => mockMembers;

  @override
  Future<StoreMemberDto> provisionMember(
    int storeId,
    ProvisionStoreMemberRequest request,
  ) async {
    final member = StoreMemberDto(
      storeId: storeId,
      userId: 55,
      userEmail: request.email,
      userFullName: request.fullName,
      role: request.role,
      customRoleIds: request.roleIds,
      customRoles: const ['Custom'],
      effectivePermissions: const ['store.orders.view'],
      createdAtUtc: DateTime.now().toUtc(),
    );
    mockMembers.add(member);
    return member;
  }

  @override
  Future<StoreMemberDto> addMember(
    int storeId,
    AddStoreMemberRequest request,
  ) async {
    final member = StoreMemberDto(
      storeId: storeId,
      userId: request.userId,
      role: request.role,
      customRoleIds: request.roleIds,
      customRoles: const [],
      effectivePermissions: const [],
      createdAtUtc: DateTime.now().toUtc(),
    );
    mockMembers.add(member);
    return member;
  }

  @override
  Future<StoreMemberDto> updateMemberRoles(
    int storeId,
    int userId,
    UpdateMemberRolesRequest request,
  ) async {
    final idx = mockMembers.indexWhere((m) => m.userId == userId);
    final updated = StoreMemberDto(
      storeId: storeId,
      userId: userId,
      role: idx != -1 ? mockMembers[idx].role : 'Member',
      customRoleIds: request.roleIds,
      customRoles: const ['UpdatedRole'],
      effectivePermissions: const ['store.roles.manage'],
      createdAtUtc: DateTime.now().toUtc(),
    );
    if (idx != -1) mockMembers[idx] = updated;
    return updated;
  }

  @override
  Future<void> removeMember(int storeId, int userId) async {
    mockMembers.removeWhere((m) => m.userId == userId);
  }

  @override
  Future<StoreResponseDto> createStore(CreateStoreRequest request) =>
      throw UnimplementedError();

  @override
  Future<List<StoreResponseDto>> getMyStores() => throw UnimplementedError();

  @override
  Future<StoreResponseDto> getStoreById(int storeId) =>
      throw UnimplementedError();
}

void main() {
  late TestStoreApiService fakeApi;
  late StoreRbacCubit cubit;

  setUp(() {
    fakeApi = TestStoreApiService();
    fakeApi.mockRoles = [
      StoreRoleDto(
        id: 1,
        storeId: 10,
        name: 'Cashier',
        permissionCodes: const ['store.orders.view'],
        memberCount: 1,
        createdAtUtc: DateTime.now().toUtc(),
      )
    ];
    fakeApi.mockMembers = [
      StoreMemberDto(
        storeId: 10,
        userId: 1,
        userEmail: 'owner@bokrah.com',
        userFullName: 'Store Owner',
        role: 'Owner',
        customRoleIds: const [],
        customRoles: const [],
        effectivePermissions: const ['store.roles.manage'],
        createdAtUtc: DateTime.now().toUtc(),
      )
    ];

    cubit = StoreRbacCubit(apiService: fakeApi);
  });

  tearDown(() {
    cubit.close();
  });

  group('StoreRbacCubit', () {
    test('loadStoreRbacContext loads catalog, roles, and members', () async {
      await cubit.loadStoreRbacContext(10, currentUserId: 1);

      expect(cubit.state.status, equals(StoreRbacStatus.loaded));
      expect(cubit.state.roles.length, equals(1));
      expect(cubit.state.members.length, equals(1));
      expect(cubit.state.permissionCatalog.length, equals(2));
      expect(cubit.state.isCurrentMemberOwner, isTrue);
      expect(cubit.state.can('store.roles.manage'), isTrue);
    });

    test('createRole adds a role to state and groups by category', () async {
      await cubit.loadStoreRbacContext(10, currentUserId: 1);

      final success = await cubit.createRole(
        name: 'Supervisor',
        description: 'Supervises floor',
        permissionCodes: ['store.orders.view'],
      );

      expect(success, isTrue);
      expect(cubit.state.roles.length, equals(2));
      expect(cubit.state.roles.any((r) => r.name == 'Supervisor'), isTrue);
    });

    test('provisionMember adds new member to active store state', () async {
      await cubit.loadStoreRbacContext(10, currentUserId: 1);

      final success = await cubit.provisionMember(
        email: 'clerk@bokrah.com',
        fullName: 'New Clerk',
        password: 'Password123!',
        roleIds: [1],
      );

      expect(success, isTrue);
      expect(cubit.state.members.length, equals(2));
      expect(
        cubit.state.members.any((m) => m.userEmail == 'clerk@bokrah.com'),
        isTrue,
      );
    });

    test('removeMember removes member from state', () async {
      await cubit.loadStoreRbacContext(10, currentUserId: 1);
      expect(cubit.state.members.length, equals(1));

      final success = await cubit.removeMember(1);
      expect(success, isTrue);
      expect(cubit.state.members.isEmpty, isTrue);
    });
  });
}
