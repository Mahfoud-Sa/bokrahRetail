import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/core/auth/app_access_guard.dart';
import 'package:bokrah_retail/app/features/categories/domain/entities/category_entity.dart';
import 'package:bokrah_retail/app/features/departments/domain/entities/department_entity.dart';
import 'package:bokrah_retail/app/features/items/domain/entities/item_entity.dart';
import 'package:bokrah_retail/app/features/categories/data/services/categories_service.dart';
import 'package:bokrah_retail/app/features/departments/data/services/departments_service.dart';
import 'package:bokrah_retail/app/features/items/data/services/items_service.dart';
import 'package:bokrah_retail/app/features/units/domain/entities/unit_entity.dart';
import 'package:bokrah_retail/app/features/units/domain/usecases/unit_usecases.dart';
import 'package:bokrah_retail/app/features/units/data/datasources/unit_local_datasource.dart';
import 'package:bokrah_retail/app/features/units/data/repositories/unit_repository_impl.dart';

import 'package:bokrah_retail/app/features/items/presentation/widgets/barcode_scanner_dialog.dart';
import 'package:bokrah_retail/app/core/widgets/widgets.dart';

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
  final DepartmentsService _departmentsService = DepartmentsService();
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

  // Specifications
  late final TextEditingController _colorController;
  late final TextEditingController _sizeController;
  late final TextEditingController _qrCodeController;

  List<DepartmentEntity> _departments = [];
  int? _selectedDepartmentId;
  List<CategoryEntity> _categories = [];
  int? _selectedCategoryId;
  List<String> _barcodes = [];
  List<UnitEntity> _units = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;

    _nameController = TextEditingController(text: item?.name ?? '');
    _subnameController =
        TextEditingController(text: item?.effectiveSubname ?? '');
    _usageStatus = item?.usageStatus ?? ItemUsageStatus.newItem;

    _mainImageController =
        TextEditingController(text: item?.effectiveMainImage ?? '');
    _subImages = List.from(item?.effectiveSubImages ?? []);
    _videoController = TextEditingController(text: item?.video ?? '');

    _companyController =
        TextEditingController(text: item?.effectiveCompany ?? '');
    _brandController = TextEditingController(text: item?.brand ?? '');
    _manufactureYearController = TextEditingController(
      text: item?.manufactureYear != null
          ? item!.manufactureYear.toString()
          : '',
    );

    _shortDescriptionController =
        TextEditingController(text: item?.shortDescription ?? '');
    _fullDescriptionController =
        TextEditingController(text: item?.effectiveFullDescription ?? '');

    _sellPriceController = TextEditingController(
      text: item != null ? item.sellPrice.toString() : '',
    );
    _purchasePriceController = TextEditingController(
      text: item != null ? item.purchasePrice.toString() : '',
    );
    _quantityController = TextEditingController(
      text: item != null ? item.quantity.toString() : '',
    );

    _colorController = TextEditingController(text: item?.color ?? '');
    _sizeController = TextEditingController(text: item?.size ?? '');
    _qrCodeController = TextEditingController(text: item?.qrCode ?? '');

    _selectedDepartmentId =
        item?.effectiveDepartmentId ?? widget.initialDepartmentId;
    _selectedCategoryId =
        item?.effectiveCategoryId ?? widget.initialCategoryId;
    _barcodes = List.from(item?.barcodes ?? []);

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final departments = await _departmentsService.getAllDepartments();
      final categories = await _categoriesService.getAllCategories();
      final loadedUnits = await _loadUnitsForItem();

      if (!mounted) return;
      setState(() {
        _departments = departments;
        _categories = categories;
        _units = loadedUnits;
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
        final unitDataSource =
            UnitLocalDataSourceImpl(sharedPreferences: prefs);
        final unitRepo = UnitRepositoryImpl(localDataSource: unitDataSource);
        final getUnitsByItemId = GetUnitsByItemIdUseCase(unitRepo);
        return await getUnitsByItemId(widget.item!.id!);
      } catch (_) {
        return [];
      }
    } else {
      return [
        UnitEntity(
          name: 'حبة',
          factor: 1.0,
          itemId: 0,
        ),
      ];
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
    _colorController.dispose();
    _sizeController.dispose();
    _qrCodeController.dispose();
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
      company: _companyController.text.trim().isEmpty
          ? null
          : _companyController.text.trim(),
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
      color: _colorController.text.trim().isEmpty
          ? null
          : _colorController.text.trim(),
      size: _sizeController.text.trim().isEmpty
          ? null
          : _sizeController.text.trim(),
      qrCode: _qrCodeController.text.trim().isEmpty
          ? null
          : _qrCodeController.text.trim(),
      departmentId: _selectedDepartmentId,
      categoryId: _selectedCategoryId,
      barcodes: _barcodes,
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

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Basic Info & Usage Status
                FormSectionCard(
                  title: 'المعلومات الأساسية وحالة الاستخدام',
                  icon: Icons.info_outline,
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'اسم العنصر *',
                      icon: Icons.title,
                      validator: (v) =>
                          v == null || v.trim().isEmpty
                              ? 'يرجى إدخال اسم العنصر'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _subnameController,
                      label: 'الاسم الفرعي / الإضافي (Subname)',
                      icon: Icons.subtitles_outlined,
                      hintText: 'مثال: الإصدار الثاني / الطراز الفضي',
                    ),
                    const SizedBox(height: 16),
                    _buildUsageStatusSection(),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. Department & Category Tree Classification
                FormSectionCard(
                  title: 'القسم وتصنيف شجرة الفئات (Department & Category Tree)',
                  icon: Icons.account_tree_outlined,
                  children: [
                    _buildDepartmentSelector(),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    _buildCategorySelector(),
                  ],
                ),
                const SizedBox(height: 16),

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
                const SizedBox(height: 16),

                // 4. Manufacturer, Brand & Year
                FormSectionCard(
                  title: 'بيانات الصنع والعلامة التجارية',
                  icon: Icons.business_outlined,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _companyController,
                            label: 'الشركة المصنعة (Company)',
                            icon: Icons.domain,
                            hintText: 'مثال: شركة التقنية المتحدة',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _brandController,
                            label: 'العلامة التجارية (Brand)',
                            icon: Icons.branding_watermark_outlined,
                            hintText: 'مثال: Samsung, Apple, Sony',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
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
                const SizedBox(height: 16),

                // 5. Descriptions (Short and Full)
                FormSectionCard(
                  title: 'الوصف والتفاصيل',
                  icon: Icons.notes_outlined,
                  children: [
                    _buildTextField(
                      controller: _shortDescriptionController,
                      label: 'الوصف المختصر (Short Description)',
                      icon: Icons.short_text,
                      maxLines: 2,
                      hintText: 'ملخص موجز يظهر في القوائم السريعة والفواتير',
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _fullDescriptionController,
                      label: 'الوصف الكامل (Full Description)',
                      icon: Icons.description_outlined,
                      maxLines: 4,
                      hintText:
                          'شرح مفصل لكافة مواصفات العنصر وميزاته والضمان',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 6. Pricing, Stock & Units
                FormSectionCard(
                  title: 'التسعير والمخزون والوحدات',
                  icon: Icons.price_change_outlined,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _purchasePriceController,
                            label: 'سعر الشراء',
                            icon: Icons.shopping_cart_outlined,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            suffixText: 'ر.س',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _sellPriceController,
                            label: 'سعر البيع',
                            icon: Icons.attach_money,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            suffixText: 'ر.س',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _quantityController,
                            label: 'الكمية (بالوحدة الأساسية)',
                            icon: Icons.inventory_2_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: _manageUnits,
                            child: IgnorePointer(
                              child: TextFormField(
                                decoration: _buildInputDecoration(
                                  'إدارة الوحدات (${_units.length})',
                                  Icons.straighten,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 7. Specifications & Barcodes
                FormSectionCard(
                  title: 'المواصفات الإضافية والباركود',
                  icon: Icons.qr_code_2_outlined,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _colorController,
                            label: 'اللون',
                            icon: Icons.palette_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _sizeController,
                            label: 'المقاس / الحجم',
                            icon: Icons.aspect_ratio_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _qrCodeController,
                      label: 'رمز QR',
                      icon: Icons.qr_code,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner),
                        onPressed: () async {
                          final scanned = await showDialog<String>(
                            context: context,
                            builder: (context) => const BarcodeScannerDialog(),
                          );
                          if (scanned != null) {
                            setState(() => _qrCodeController.text = scanned);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    ItemBarcodesSection(
                      barcodes: _barcodes,
                      onBarcodesChanged: (updated) {
                        setState(() => _barcodes = updated);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDepartmentSelector() {
    final validDepartmentId =
        _departments.any((d) => d.id == _selectedDepartmentId)
            ? _selectedDepartmentId
            : null;
    final selectedDept = validDepartmentId != null
        ? _departments.firstWhere((d) => d.id == validDepartmentId)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.domain_outlined,
                  size: 18,
                  color: AppTheme.actionBlue,
                ),
                SizedBox(width: 6),
                Text(
                  'القسم التابع له العنصر (Department)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: _quickAddDepartment,
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: const Text(
                'إضافة قسم سريع',
                style: TextStyle(fontSize: 12),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'العنصر يتبع لقسم واحد فقط ضمن النظام (علاقة 1 إلى متعدد)',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        if (selectedDept != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.actionBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.actionBlue.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.apartment_rounded,
                  color: AppTheme.actionBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedDept.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.deepCobalt,
                          fontSize: 13,
                        ),
                      ),
                      if (selectedDept.code != null)
                        Text(
                          'كود القسم: ${selectedDept.code}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                  tooltip: 'إلغاء تحديد القسم',
                  onPressed: () => setState(() => _selectedDepartmentId = null),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        DropdownButtonFormField<int?>(
          initialValue: validDepartmentId,
          decoration: _buildInputDecoration(
            'اختر قسم العنصر من القائمة',
            Icons.domain_outlined,
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text(
                'بدون قسم (عام)',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ..._departments.map((d) {
              return DropdownMenuItem<int?>(
                value: d.id,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.apartment_outlined,
                      size: 16,
                      color: AppTheme.actionBlue,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        d.code != null ? '${d.name} (${d.code})' : d.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.deepCobalt,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          onChanged: (v) => setState(() => _selectedDepartmentId = v),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    final validCategoryId =
        _categories.any((c) => c.id == _selectedCategoryId)
            ? _selectedCategoryId
            : null;
    final selectedCat = validCategoryId != null
        ? _categories.firstWhere((c) => c.id == validCategoryId)
        : null;
    final selectedPath = validCategoryId != null
        ? _categoriesService.getCategoryPath(validCategoryId, _categories)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.account_tree_outlined,
                  size: 18,
                  color: AppTheme.deepCobalt,
                ),
                SizedBox(width: 6),
                Text(
                  'الفئة من شجرة الفئات (Category Tree)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
            Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: _openCategoryTreePicker,
                  icon: const Icon(Icons.account_tree_outlined, size: 15),
                  label: const Text(
                    'تصفح الشجرة',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                TextButton.icon(
                  onPressed: _quickAddCategory,
                  icon: const Icon(Icons.add_circle_outline, size: 15),
                  label: const Text(
                    'إضافة فئة',
                    style: TextStyle(fontSize: 11),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'يمكن تعيين العنصر لأي فئة رئيسية أو متفرعة في شجرة الفئات',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        if (selectedCat != null && selectedPath != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.deepCobalt.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.deepCobalt.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_tree_rounded,
                  color: AppTheme.deepCobalt,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedPath,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.deepCobalt,
                          fontSize: 13,
                        ),
                      ),
                      if (selectedCat.code != null)
                        Text(
                          'كود الفئة: ${selectedCat.code}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                  tooltip: 'إلغاء تحديد الفئة',
                  onPressed: () => setState(() => _selectedCategoryId = null),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        DropdownButtonFormField<int?>(
          initialValue: validCategoryId,
          decoration: _buildInputDecoration(
            'اختر الفئة من القائمة أو تصفح الشجرة',
            Icons.account_tree_outlined,
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text(
                'بدون فئة (غير مصنف)',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ..._categories.map((c) {
              final path = _categoriesService.getCategoryPath(
                c.id!,
                _categories,
              );
              final isRoot = c.isRoot;
              return DropdownMenuItem<int?>(
                value: c.id,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isRoot
                          ? Icons.folder_outlined
                          : Icons.subdirectory_arrow_left,
                      size: 15,
                      color: isRoot ? AppTheme.deepCobalt : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        path,
                        style: TextStyle(
                          fontWeight: isRoot
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isRoot ? AppTheme.deepCobalt : Colors.black87,
                          fontSize: 12.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          onChanged: (v) => setState(() => _selectedCategoryId = v),
        ),
      ],
    );
  }

  Widget _buildUsageStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'حالة الاستخدام (Usage Status) *',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ItemUsageStatus.values.map((status) {
            final isSelected = _usageStatus == status;
            final color = getItemStatusColor(status);
            final icon = getItemStatusIcon(status);

            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected ? Colors.white : color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${status.labelAr} (${status.value})',
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              selected: isSelected,
              selectedColor: color,
              backgroundColor: Colors.grey[100],
              onSelected: (selected) {
                if (selected) {
                  setState(() => _usageStatus = status);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? suffixText,
    String? hintText,
    int maxLines = 1,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
      decoration: _buildInputDecoration(label, icon).copyWith(
        suffixText: suffixText,
        hintText: hintText,
        suffixIcon: suffixIcon,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppTheme.actionBlue),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.actionBlue, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
}

