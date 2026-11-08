import 'package:bokrah_retail/app/features/items/data/services/items_service.dart';
import 'package:bokrah_retail/app/features/units/data/datasources/unit_local_datasource.dart';
import 'package:bokrah_retail/app/features/units/data/repositories/unit_repository_impl.dart';
import 'package:bokrah_retail/app/features/units/domain/usecases/unit_usecases.dart';
import 'package:bokrah_retail/app/features/units/presentation/cubits/unit_cubit.dart';
import 'package:bokrah_retail/app/features/units/presentation/cubits/unit_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UnitsPage extends StatelessWidget {
  const UnitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final prefs = snapshot.data!;
        final dataSource = UnitLocalDataSourceImpl(sharedPreferences: prefs);
        final repository = UnitRepositoryImpl(localDataSource: dataSource);

        return BlocProvider(
          create: (context) => UnitCubit(
            getAllUnitsUseCase: GetAllUnitsUseCase(repository),
            getUnitsByItemIdUseCase: GetUnitsByItemIdUseCase(repository),
            saveUnitsUseCase: SaveUnitsUseCase(repository),
            deleteUnitsByItemIdUseCase: DeleteUnitsByItemIdUseCase(repository),
          )..loadAllUnits(),
          child: const UnitsView(),
        );
      },
    );
  }
}

class UnitsView extends StatefulWidget {
  const UnitsView({super.key});

  @override
  State<UnitsView> createState() => _UnitsViewState();
}

class _UnitsViewState extends State<UnitsView> {
  final ItemsService _itemsService = ItemsService();
  Map<int, String> _itemNames = {};
  bool _itemsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await _itemsService.getAllItems();
    if (mounted) {
      setState(() {
        _itemNames = {for (var item in items) item.id!: item.name};
        _itemsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'الوحدات',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF2E7D64),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: _itemsLoading
            ? const Center(child: CircularProgressIndicator())
            : BlocBuilder<UnitCubit, UnitState>(
                builder: (context, state) {
                  if (state is UnitLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is UnitError) {
                    return Center(child: Text(state.message));
                  } else if (state is UnitLoaded) {
                    final units = state.units;
                    if (units.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.straighten,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد وحدات مضافة',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: units.length,
                      itemBuilder: (context, index) {
                        final unit = units[index];
                        final itemName =
                            _itemNames[unit.itemId] ?? 'عنصر غير معروف';

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: const Color(
                                0xFF2E7D64,
                              ).withOpacity(0.1),
                              child: const Icon(
                                Icons.straighten,
                                color: Color(0xFF2E7D64),
                              ),
                            ),
                            title: Text(
                              unit.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'العنصر: $itemName',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                Text(
                                  'معامل التحويل: ${unit.factor}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                if (unit.barcodes.isNotEmpty)
                                  Text(
                                    'الباركودات: ${unit.barcodes.join(", ")}',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: unit.factor == 1.0
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'وحدة أساسية',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
      ),
    );
  }
}
