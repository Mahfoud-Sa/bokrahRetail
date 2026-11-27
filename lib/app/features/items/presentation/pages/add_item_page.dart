import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/core/auth/app_access_guard.dart';
import 'package:bokrah_retail/app/features/categories/domain/entities/category_entity.dart';
import 'package:bokrah_retail/app/features/departments/domain/entities/department_entity.dart';
import 'package:bokrah_retail/app/features/items/domain/entities/item_entity.dart';
import 'package:bokrah_retail/app/features/barcoders/data/services/barcodes_service.dart';
import 'package:bokrah_retail/app/features/barcoders/domain/entities/barcode_entity.dart';
import 'package:bokrah_retail/app/features/categories/data/services/categories_service.dart';
import 'package:bokrah_retail/app/features/departments/data/services/departments_service.dart';
import 'package:bokrah_retail/app/features/items/data/services/items_service.dart';
import 'package:bokrah_retail/app/features/companies/presentation/bloc/companies_cubit.dart';
import 'package:bokrah_retail/app/features/units/domain/entities/unit_entity.dart';
import 'package:bokrah_retail/app/features/units/domain/usecases/unit_usecases.dart';
import 'package:bokrah_retail/app/features/units/data/datasources/unit_local_datasource.dart';
import 'package:bokrah_retail/app/features/units/data/repositories/unit_repository_impl.dart';

import 'package:bokrah_retail/app/core/widgets/widgets.dart';
import 'package:bokrah_retail/app/initialzation_dependencies.dart';

class AddItemPage extends StatefulWidget {
  final ItemEntity? item;
  final int? initialDepartmentId;
  final int? initialCategoryId;

  const AddItemPage({
    super.key,
    this.item,
    this.initialDepartmentId,
    this.initialCategoryId,
  });

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final _formKey = GlobalKey<FormState>();
  final ItemsService _itemsService = ItemsService();
  final BarcodesService _barcodesService = BarcodesService();
  final DepartmentsService _departmentsService =
      singelton.isRegistered<DepartmentsService>()
      ? singelton<DepartmentsService>()
      : DepartmentsService();
  final CategoriesService _categoriesService = CategoriesService();

  // Basic Information
  late final TextEditingController _nameController;
  late final TextEditingController _subnameController;
  late ItemUsageStatus _usageStatus;

  // Media
  late final TextEditingController _mainImageController;
  List<String> _subImages = [];
  late final TextEditingController _videoController;

  // Brand, Company, Year
  late final TextEditingController _companyController;
  late final TextEditingController _brandController;
  late final TextEditingController _manufactureYearController;

  // Descriptions
  late final TextEditingController _shortDescriptionController;
  late final TextEditingController _fullDescriptionController;

  // Pricing & Inventory
  late final TextEditingController _sellPriceController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _quantityController;

  List<DepartmentEntity> _departments = [];
  int? _selectedDepartmentId;
  List<CategoryEntity> _categories = [];
  int? _selectedCategoryId;
  int? _selectedCompanyId;
  List<BarcodeEntity> _allBarcodes = [];
  Set<int> _selectedBarcodeIds = {};
  List<String> _advantages = [];
  List<UnitEntity> _units = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;

    _nameController = TextEditingController(text: item?.name ?? '');
    _subnameController = TextEditingController(
      text: item?.effectiveSubname ?? '',
    );
    _usageStatus = item?.usageStatus ?? ItemUsageStatus.newItem;

    _mainImageController = TextEditingController(
      text: item?.effectiveMainImage ?? '',
    );
    _subImages = List.from(item?.effectiveSubImages ?? []);
    _videoController = TextEditingController(text: item?.video ?? '');

    _companyController = TextEditingController(
      text: item?.effectiveCompany ?? '',
    );
    _brandController = TextEditingController(text: item?.brand ?? '');
    _manufactureYearController = TextEditingController(
      text: item?.manufactureYear != null
          ? item!.manufactureYear.toString()
          : '',
    );

    _shortDescriptionController = TextEditingController(
      text: item?.shortDescription ?? '',
    );
    _fullDescriptionController = TextEditingController(
      text: item?.effectiveFullDescription ?? '',
    );

    _sellPriceController = TextEditingController(
      text: item != null ? item.sellPrice.toString() : '',
    );
    _purchasePriceController = TextEditingController(
      text: item != null ? item.purchasePrice.toString() : '',
    );
    _quantityController = TextEditingController(
      text: item != null ? item.quantity.toString() : '',
    );

    _selectedDepartmentId =
        item?.effectiveDepartmentId ?? widget.initialDepartmentId;
    _selectedCategoryId = item?.effectiveCategoryId ?? widget.initialCategoryId;
    _advantages = List.from(item?.advantages ?? const []);

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final companiesLoad = context
          .read<CompaniesCubit>()
          .loadCompanyDirectory();
      final departments = await _departmentsService.getAllDepartments();
      final categories = await _categoriesService.getAllCategories();
      final allBarcodes = await _barcodesService.getAllBarcodes();
      final linkedBarcodeIds = widget.item?.id != null
          ? (await _barcodesService.getBarcodeIdsByItem(
              widget.item!.id!,
            )).toSet()
          : <int>{};
      final loadedUnits = await _loadUnitsForItem();
      await companiesLoad;

      if (!mounted) return;
      final existingCompany = widget.item == null
          ? null
          : context
                .read<CompaniesCubit>()
                .state
                .companies
                .where(
                  (company) =>
                      company.matchesName(widget.item!.effectiveCompany ?? ''),
                )
                .firstOrNull;
      setState(() {
        _departments = departments;
        _categories = categories;
        _allBarcodes = allBarcodes;
        _selectedBarcodeIds = linkedBarcodeIds;
        _units = loadedUnits;
        _selectedCompanyId = existingCompany?.id;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<List<UnitEntity>> _loadUnitsForItem() async {
    if (widget.item != null && widget.item!.id != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final unitDataSource = UnitLocalDataSourceImpl(
          sharedPreferences: prefs,
        );
        final unitRepo = UnitRepositoryImpl(localDataSource: unitDataSource);
        final getUnitsByItemId = GetUnitsByItemIdUseCase(unitRepo);
        return await getUnitsByItemId(widget.item!.id!);
      } catch (_) {
        return [];
      }
    } else {
      return [UnitEntity(name: 'حبة', factor: 1.0, itemId: 0)];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subnameController.dispose();
    _mainImageController.dispose();
    _videoController.dispose();
    _companyController.dispose();
    _brandController.dispose();
    _manufactureYearController.dispose();
    _shortDescriptionController.dispose();
    _fullDescriptionController.dispose();
    _sellPriceController.dispose();
    _purchasePriceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _manageUnits() {
    ItemUnitsSheet.show(
      context,
      units: _units,
      itemId: widget.item?.id,
      onUnitsChanged: (updated) {
        setState(() => _units = updated);
      },
    );
  }

  Future<void> _quickAddDepartment() async {
    final newDept = await QuickAddDepartmentDialog.show(
      context,
      departmentsService: _departmentsService,
    );
    if (newDept != null) {
      final all = await _departmentsService.getAllDepartments();
      if (!mounted) return;
      setState(() {
        _departments = all;
        _selectedDepartmentId = newDept.id;
      });
    }
  }

  Future<void> _quickAddCategory() async {
    final newCat = await QuickAddCategoryDialog.show(
      context,
      categoriesService: _categoriesService,
      categories: _categories,
      defaultParentId: _selectedCategoryId,
    );
    if (newCat != null) {
      final all = await _categoriesService.getAllCategories();
      if (!mounted) return;
      setState(() {
        _categories = all;
        _selectedCategoryId = newCat.id;
      });
    }
  }

  void _openCategoryTreePicker() {
    CategoryTreePickerSheet.show(
      context,
      categories: _categories,
      selectedCategoryId: _selectedCategoryId,
      categoriesService: _categoriesService,
      onSelected: (val) {
        setState(() => _selectedCategoryId = val);
      },
    );
  }

  Future<void> _saveItem() async {
    if (!await AppAccessGuard.requireStore(
      context: context,
      returnRoute: '/add-item',
    )) {
      return;
    }
    if (!mounted) return;

    if (!_formKey.currentState!.validate()) return;

    if (_units.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إضافة وحدة واحدة على الأقل')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final itemToSave = ItemEntity(
      id: widget.item?.id,
      name: _nameController.text.trim(),
      subname: _subnameController.text.trim().isEmpty
          ? null
          : _subnameController.text.trim(),
      usageStatus: _usageStatus,
      mainImage: _mainImageController.text.trim().isEmpty
          ? null
          : _mainImageController.text.trim(),
      subImages: _subImages,
      video: _videoController.text.trim().isEmpty
          ? null
          : _videoController.text.trim(),
      company: _selectedCompanyId == null
          ? (_companyController.text.trim().isEmpty
                ? null
                : _companyController.text.trim())
          : (context
                    .read<CompaniesCubit>()
                    .state
                    .companies
                    .where((company) => company.id == _selectedCompanyId)
                    .firstOrNull
                    ?.localizedName(
                      Localizations.localeOf(context).languageCode == 'ar',
                    ) ??
                (_companyController.text.trim().isEmpty
                    ? null
                    : _companyController.text.trim())),
      brand: _brandController.text.trim().isEmpty
          ? null
          : _brandController.text.trim(),
      manufactureYear: int.tryParse(_manufactureYearController.text.trim()),
      shortDescription: _shortDescriptionController.text.trim().isEmpty
          ? null
          : _shortDescriptionController.text.trim(),
      fullDescription: _fullDescriptionController.text.trim().isEmpty
          ? null
          : _fullDescriptionController.text.trim(),
      sellPrice: double.tryParse(_sellPriceController.text) ?? 0.0,
      purchasePrice: double.tryParse(_purchasePriceController.text) ?? 0.0,
      quantity: int.tryParse(_quantityController.text) ?? 0,
      color: widget.item?.color,
      size: widget.item?.size,
      qrCode: widget.item?.qrCode,
      departmentId: _selectedDepartmentId,
      categoryId: _selectedCategoryId,
      barcodes: _allBarcodes
          .where((b) => b.id != null && _selectedBarcodeIds.contains(b.id))
          .map((b) => b.code)
          .toList(),
      advantages: _advantages,
      createdAt: widget.item?.createdAt,
    );

    ItemEntity? savedItem;
    bool itemSuccess = false;

    if (widget.item != null) {
      itemSuccess = await _itemsService.updateItem(itemToSave);
      savedItem = itemToSave;
    } else {
      savedItem = await _itemsService.saveItem(itemToSave);
      itemSuccess = savedItem != null;
    }

    if (itemSuccess && savedItem != null) {
      final unitsToSave = _units.map((u) {
        return UnitEntity(
          id: u.id,
          name: u.name,
          factor: u.factor,
          itemId: savedItem!.id!,
          barcodes: u.barcodes,
        );
      }).toList();

      final prefs = await SharedPreferences.getInstance();
      final unitDataSource = UnitLocalDataSourceImpl(sharedPreferences: prefs);
      final unitRepo = UnitRepositoryImpl(localDataSource: unitDataSource);
      final saveUnits = SaveUnitsUseCase(unitRepo);

      await saveUnits(unitsToSave);
      await _barcodesService.syncBarcodesForItem(
        savedItem.id!,
        _selectedBarcodeIds,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.item != null ? 'تم التحديث بنجاح' : 'تم الحفظ بنجاح',
          ),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context, true);
    } else {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء حفظ العنصر'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _addNewCompany() async {
    final added = await context.push<bool>('/add-company');
    if (added == true && mounted) {
      await context.read<CompaniesCubit>().loadCompanyDirectory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final companiesState = context.watch<CompaniesCubit>().state;
    final companies = companiesState.companies;
    final isEditing = widget.item != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'تعديل عنصر' : 'إضافة عنصر جديد'),
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          actions: [
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: FilledButton.icon(
                  onPressed: _saveItem,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('حفظ العنصر'),
                ),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Form(
                key: _formKey,
                child: ResponsiveFormGrid(
                  sections: [
                    // 1. Basic Info & Usage Status
                    FormSectionCard(
                      title: 'المعلومات الأساسية وحالة الاستخدام',
                      icon: Icons.info_outline,
                      children: [
                        AppFormTextField(
                          controller: _nameController,
                          label: 'اسم العنصر *',
                          icon: Icons.title,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'يرجى إدخال اسم العنصر'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        AppFormTextField(
                          controller: _subnameController,
                          label: 'الاسم الفرعي / الإضافي (Subname)',
                          icon: Icons.subtitles_outlined,
                          hintText: 'مثال: الإصدار الثاني / الطراز الفضي',
                        ),
                        const SizedBox(height: 16),
                        ItemUsageStatusSelector(
                          value: _usageStatus,
                          onChanged: (status) {
                            setState(() => _usageStatus = status);
                          },
                        ),
                      ],
                    ),

                    // 2. Department & Category Tree Classification
                    FormSectionCard(
                      title:
                          'القسم وتصنيف شجرة الفئات (Department & Category Tree)',
                      icon: Icons.account_tree_outlined,
                      children: [
                        ItemDepartmentSelector(
                          departments: _departments,
                          selectedDepartmentId: _selectedDepartmentId,
                          onChanged: (val) {
                            setState(() => _selectedDepartmentId = val);
                          },
                          onQuickAdd: _quickAddDepartment,
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),
                        ItemCategorySelector(
                          categories: _categories,
                          selectedCategoryId: _selectedCategoryId,
                          categoryPathBuilder: (id) => _categoriesService
                              .getCategoryPath(id, _categories),
                          onChanged: (val) {
                            setState(() => _selectedCategoryId = val);
                          },
                          onBrowseTree: _openCategoryTreePicker,
                          onQuickAdd: _quickAddCategory,
                        ),
                      ],
                    ),

                    // 3. Media Section (Main Image, Subimages, Video)
                    FormSectionCard(
                      title: 'الصور والوسائط (Media)',
                      icon: Icons.perm_media_outlined,
                      children: [
                        ItemMediaSection(
                          mainImageController: _mainImageController,
                          subImages: _subImages,
                          onSubImagesChanged: (updated) {
                            setState(() => _subImages = updated);
                          },
                          videoController: _videoController,
                        ),
                      ],
                    ),

                    // 4. Manufacturer, Brand & Year
                    FormSectionCard(
                      title: 'بيانات الصنع والعلامة التجارية',
                      icon: Icons.business_outlined,
                      children: [
                        ItemCompanyBrandSelector(
                          companies: companies,
                          selectedCompanyId: _selectedCompanyId,
                          isLoading: companiesState.isDirectoryLoading,
                          isRequired: !isEditing,
                          companyController: _companyController,
                          brandController: _brandController,
                          onCompanyChanged: (id) {
                            setState(() => _selectedCompanyId = id);
                          },
                          onAddCompany: _addNewCompany,
                        ),
                        const SizedBox(height: 12),
                        AppFormTextField(
                          controller: _manufactureYearController,
                          label: 'سنة الصنع (Manufacture Year)',
                          icon: Icons.calendar_today_outlined,
                          keyboardType: TextInputType.number,
                          hintText: 'مثال: 2024',
                          validator: (v) {
                            if (v != null && v.trim().isNotEmpty) {
                              final year = int.tryParse(v.trim());
                              if (year == null || year < 1900 || year > 2100) {
                                return 'يرجى إدخال سنة صنع صالحة (مثال: 2024)';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),

                    // 5. Descriptions (Short and Full)
                    FormSectionCard(
                      title: 'الوصف والتفاصيل',
                      icon: Icons.notes_outlined,
                      children: [
                        AppFormTextField(
                          controller: _shortDescriptionController,
                          label: 'الوصف المختصر (Short Description)',
                          icon: Icons.short_text,
                          maxLines: 2,
                          hintText:
                              'ملخص موجز يظهر في القوائم السريعة والفواتير',
                        ),
                        const SizedBox(height: 12),
                        AppFormTextField(
                          controller: _fullDescriptionController,
                          label: 'الوصف الكامل (Full Description)',
                          icon: Icons.description_outlined,
                          maxLines: 4,
                          hintText:
                              'شرح مفصل لكافة مواصفات العنصر وميزاته والضمان',
                        ),
                      ],
                    ),

                    // 6. Pricing, Stock & Units
                    FormSectionCard(
                      title: 'التسعير والمخزون والوحدات',
                      icon: Icons.price_change_outlined,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _manageUnits,
                                child: IgnorePointer(
                                  child: TextFormField(
                                    decoration: buildAppInputDecoration(
                                      label: 'إدارة الوحدات (${_units.length})',
                                      icon: Icons.straighten,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // 7. Advantages
                    FormSectionCard(
                      title: 'المميزات (Advantages)',
                      icon: Icons.star_outline,
                      children: [
                        ItemAdvantagesSection(
                          advantages: _advantages,
                          onAdvantagesChanged: (updated) {
                            setState(() => _advantages = updated);
                          },
                        ),
                      ],
                    ),

                    // 8. Linked Barcodes (M:M)
                    FormSectionCard(
                      title: 'الباركودات المرتبطة',
                      icon: Icons.qr_code_2_outlined,
                      children: [
                        ItemBarcodeLinksSelector(
                          availableBarcodes: _allBarcodes,
                          selectedBarcodeIds: _selectedBarcodeIds,
                          onSelectionChanged: (updated) {
                            setState(() => _selectedBarcodeIds = updated);
                          },
                          onCreateBarcode: (code, label) async {
                            final existing = _allBarcodes
                                .where((b) => b.code == code)
                                .firstOrNull;
                            if (existing != null) return existing;

                            final newBarcode = BarcodeEntity(
                              id: DateTime.now().millisecondsSinceEpoch,
                              code: code,
                              label: label,
                            );
                            final ok = await _barcodesService.saveBarcode(
                              newBarcode,
                            );
                            if (!ok) return null;
                            final reloaded = await _barcodesService
                                .getAllBarcodes();
                            if (mounted) {
                              setState(() => _allBarcodes = reloaded);
                            }
                            return reloaded
                                .where((b) => b.code == code)
                                .firstOrNull;
                          },
                        ),
                      ],
                    ),
                  ],
                  footer: FormActionBar(
                    isSubmitting: _isLoading,
                    submitLabel: isEditing ? 'حفظ التعديلات' : 'حفظ العنصر',
                    onSubmit: _saveItem,
                    onCancel: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
