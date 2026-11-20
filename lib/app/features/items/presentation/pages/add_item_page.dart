import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/features/items/data/entities/category_entity.dart';
import 'package:bokrah_retail/app/features/items/data/entities/department_entity.dart';
import 'package:bokrah_retail/app/features/items/data/entities/item_entity.dart';
import 'package:bokrah_retail/app/features/items/data/services/categories_service.dart';
import 'package:bokrah_retail/app/features/items/data/services/departments_service.dart';
import 'package:bokrah_retail/app/features/items/data/services/items_service.dart';
import 'package:bokrah_retail/app/features/units/domain/entities/unit_entity.dart';
import 'package:bokrah_retail/app/features/units/domain/usecases/unit_usecases.dart';
import 'package:bokrah_retail/app/features/units/data/datasources/unit_local_datasource.dart';
import 'package:bokrah_retail/app/features/units/data/repositories/unit_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bokrah_retail/app/features/items/presentation/widgets/barcode_scanner_dialog.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bokrah_retail/app/core/auth/app_access_guard.dart';

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
  late TextEditingController _nameController;
  late TextEditingController _subnameController;
  late ItemUsageStatus _usageStatus;

  // Media
  late TextEditingController _mainImageController;
  List<String> _subImages = [];
  late TextEditingController _videoController;

  // Brand, Company, Year
  late TextEditingController _companyController;
  late TextEditingController _brandController;
  late TextEditingController _manufactureYearController;

  // Descriptions
  late TextEditingController _shortDescriptionController;
  late TextEditingController _fullDescriptionController;

  // Pricing & Inventory
  late TextEditingController _sellPriceController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _quantityController;

  // Specifications
  late TextEditingController _colorController;
  late TextEditingController _sizeController;
  late TextEditingController _qrCodeController;

  List<DepartmentEntity> _departments = [];
  int? _selectedDepartmentId;
  List<CategoryEntity> _categories = [];
  int? _selectedCategoryId;
  String _categoryTreeSearchQuery = '';
  List<String> _barcodes = [];
  bool _isLoading = false;

  List<UnitEntity> _units = [];

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
      _departments = departments;
      _categories = categories;

      if (widget.item != null && widget.item!.id != null) {
        final prefs = await SharedPreferences.getInstance();
        final unitDataSource = UnitLocalDataSourceImpl(
          sharedPreferences: prefs,
        );
        final unitRepo = UnitRepositoryImpl(localDataSource: unitDataSource);
        final getUnitsByItemId = GetUnitsByItemIdUseCase(unitRepo);

        _units = await getUnitsByItemId(widget.item!.id!);
      } else {
        // New item: Add a default base unit
        _units = [
          UnitEntity(
            name: 'حبة',
            factor: 1.0,
            itemId: 0, // Temporary ID
          ),
        ];
      }
    } finally {
      setState(() => _isLoading = false);
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

  void _addBarcode() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة باركود'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'الباركود',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () async {
                      final scanned = await showDialog<String>(
                        context: context,
                        builder: (context) => const BarcodeScannerDialog(),
                      );
                      if (scanned != null) {
                        controller.text = scanned;
                      }
                    },
                  ),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() => _barcodes.add(controller.text.trim()));
                }
                Navigator.pop(context);
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  void _manageUnits() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => StatefulBuilder(
          builder: (context, setModalState) => Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'إدارة الوحدات',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showAddUnitDialog(setModalState),
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة وحدة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: _units.length,
                      itemBuilder: (context, index) {
                        final unit = _units[index];
                        final isBase = unit.factor == 1.0;
                        return Card(
                          child: ListTile(
                            title: Text(unit.name),
                            subtitle: Text(
                              isBase
                                  ? 'الوحدة الأساسية'
                                  : 'المعامل: ${unit.factor}',
                            ),
                            trailing: isBase
                                ? const Icon(
                                    Icons.star,
                                    color: AppTheme.warmOrange,
                                  )
                                : IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: AppTheme.error,
                                    ),
                                    onPressed: () {
                                      setState(() => _units.removeAt(index));
                                      setModalState(() {});
                                    },
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddUnitDialog(StateSetter setModalState) {
    final nameCtrl = TextEditingController();
    final factorCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة وحدة جديدة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'اسم الوحدة'),
              ),
              TextField(
                controller: factorCtrl,
                decoration: const InputDecoration(
                  labelText: 'معامل التحويل',
                  hintText: 'مثلاً: 12 للكرتون',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && factorCtrl.text.isNotEmpty) {
                  final factor = double.tryParse(factorCtrl.text) ?? 1.0;
                  setState(() {
                    _units.add(
                      UnitEntity(
                        name: nameCtrl.text.trim(),
                        factor: factor,
                        itemId: widget.item?.id ?? 0,
                      ),
                    );
                  });
                  setModalState(() {});
                  Navigator.pop(context);
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSubImageDialog() {
    final urlCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إضافة صورة فرعية'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'رابط الصورة (URL)',
                    hintText: 'https://example.com/image.jpg',
                    prefixIcon: Icon(Icons.link),
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 12),
                if (urlCtrl.text.trim().isNotEmpty) ...[
                  const Text(
                    'معاينة:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        urlCtrl.text.trim(),
                        height: 120,
                        width: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 120,
                          width: 120,
                          color: Colors.grey[200],
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, color: Colors.grey),
                              SizedBox(height: 4),
                              Text(
                                'الرابط غير صالح',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  final url = urlCtrl.text.trim();
                  if (url.isNotEmpty) {
                    setState(() => _subImages.add(url));
                    Navigator.pop(context);
                  }
                },
                child: const Text('إضافة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickAddDepartmentDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text(
            'إضافة قسم جديد',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'اسم القسم *',
                  hintText: 'مثلاً: الهواتف الذكية أو العطور',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(
                  labelText: 'كود القسم (اختياري)',
                  hintText: 'مثلاً: PHONE',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final newDept = await _departmentsService.saveDepartment(
                  DepartmentEntity(
                    name: nameCtrl.text.trim(),
                    code: codeCtrl.text.trim().isEmpty
                        ? null
                        : codeCtrl.text.trim(),
                  ),
                );
                if (newDept != null) {
                  final all = await _departmentsService.getAllDepartments();
                  setState(() {
                    _departments = all;
                    _selectedDepartmentId = newDept.id;
                  });
                }
                if (mounted) Navigator.pop(dialogCtx);
              },
              child: const Text('إضافة وتحديد'),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickAddCategoryDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    int? parentId;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'إضافة فئة جديدة في الشجرة',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'اسم الفئة *',
                      hintText: 'مثلاً: الهواتف الذكية أو العطور',
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    value: parentId,
                    decoration: const InputDecoration(
                      labelText: 'الفئة الأب (الرئيسية)',
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text(
                          'فئة رئيسية (جذر الشجرة)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ..._categories.map(
                        (c) => DropdownMenuItem<int?>(
                          value: c.id,
                          child: Text(
                            _categoriesService.getCategoryPath(
                              c.id!,
                              _categories,
                            ),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) => setDialogState(() => parentId = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'كود الفئة (اختياري)',
                      hintText: 'مثلاً: CAT-PHONE',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  final newCat = await _categoriesService.saveCategory(
                    CategoryEntity(
                      name: nameCtrl.text.trim(),
                      parentId: parentId,
                      code: codeCtrl.text.trim().isEmpty
                          ? null
                          : codeCtrl.text.trim(),
                    ),
                  );
                  if (newCat != null) {
                    final all = await _categoriesService.getAllCategories();
                    setState(() {
                      _categories = all;
                      _selectedCategoryId = newCat.id;
                    });
                  }
                  if (mounted) Navigator.pop(dialogCtx);
                },
                child: const Text('إضافة وتحديد'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveItem() async {
    if (!await AppAccessGuard.requireStore(
      context: context,
      returnRoute: '/add-item',
    )) {
      return;
    }
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
      // Save units linked to the item ID
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

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.item != null ? 'تم التحديث بنجاح' : 'تم الحفظ بنجاح',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء حفظ العنصر'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
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
                // 1. Basic Information & Usage Status
                _buildSectionCard(
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
                    // Usage Status Selector
                    _buildUsageStatusSection(),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. Department & Category Tree Classification
                _buildSectionCard(
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

                // 2. Media Section (Main Image, Subimages, Video)
                _buildSectionCard(
                  title: 'الصور والوسائط (Media)',
                  icon: Icons.perm_media_outlined,
                  children: [
                    _buildMainImageInput(),
                    const SizedBox(height: 16),
                    _buildSubImagesList(),
                    const SizedBox(height: 16),
                    _buildVideoInput(),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. Manufacturer, Brand & Year
                _buildSectionCard(
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

                // 4. Descriptions (Short and Full)
                _buildSectionCard(
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

                // 5. Pricing & Stock
                _buildSectionCard(
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

                // 6. Additional Specs & Barcodes
                _buildSectionCard(
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
                    _buildBarcodeList(),
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

  void _showCategoryTreePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final query = _categoryTreeSearchQuery.trim().toLowerCase();
          final filteredCategories = query.isEmpty
              ? _categories
              : _categories.where((c) {
                  final nameMatch = c.name.toLowerCase().contains(query);
                  final codeMatch =
                      c.code?.toLowerCase().contains(query) ?? false;
                  final pathMatch = _categoriesService
                      .getCategoryPath(c.id!, _categories)
                      .toLowerCase()
                      .contains(query);
                  return nameMatch || codeMatch || pathMatch;
                }).toList();

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 0.85,
                maxChildSize: 0.95,
                minChildSize: 0.5,
                expand: false,
                builder: (context, scrollController) => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.actionBlue.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.account_tree_rounded,
                                  color: AppTheme.actionBlue,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'تصفح واختيار من شجرة الفئات',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.deepCobalt,
                                    ),
                                  ),
                                  Text(
                                    'اضغط على أي فئة لتعيينها للعنصر مباشرة',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(sheetCtx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Search Bar
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'ابحث في أسماء أو مسارات الفئات...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () => setSheetState(
                                    () => _categoryTreeSearchQuery = '',
                                  ),
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (val) => setSheetState(
                          () => _categoryTreeSearchQuery = val,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Quick Action: "بدون فئة" (Clear selection)
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: _selectedCategoryId == null
                                ? AppTheme.actionBlue
                                : AppTheme.border,
                            width: _selectedCategoryId == null ? 1.5 : 1,
                          ),
                        ),
                        tileColor: _selectedCategoryId == null
                            ? AppTheme.actionBlue.withValues(alpha: 0.06)
                            : Colors.grey[50],
                        leading: Icon(
                          Icons.do_not_disturb_on_outlined,
                          color: _selectedCategoryId == null
                              ? AppTheme.actionBlue
                              : Colors.grey,
                        ),
                        title: const Text(
                          'بدون فئة (عنصر غير مصنف)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        trailing: _selectedCategoryId == null
                            ? const Icon(
                                Icons.check_circle,
                                color: AppTheme.actionBlue,
                                size: 20,
                              )
                            : null,
                        onTap: () {
                          setState(() => _selectedCategoryId = null);
                          Navigator.pop(sheetCtx);
                        },
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      // Tree List
                      Expanded(
                        child: filteredCategories.isEmpty
                            ? const Center(
                                child: Text(
                                  'لا توجد فئات مطابقة للبحث',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: filteredCategories.length,
                                itemBuilder: (context, index) {
                                  final cat = filteredCategories[index];
                                  final isSelected =
                                      _selectedCategoryId == cat.id;
                                  final path =
                                      _categoriesService.getCategoryPath(
                                        cat.id!,
                                        _categories,
                                      );
                                  final isRoot = cat.isRoot;

                                  return Card(
                                    elevation: 0,
                                    margin: const EdgeInsets.only(bottom: 6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: BorderSide(
                                        color: isSelected
                                            ? AppTheme.actionBlue
                                            : AppTheme.border,
                                        width: isSelected ? 1.5 : 0.8,
                                      ),
                                    ),
                                    color: isSelected
                                        ? AppTheme.actionBlue.withValues(
                                            alpha: 0.06,
                                          )
                                        : Colors.white,
                                    child: ListTile(
                                      dense: true,
                                      leading: CircleAvatar(
                                        radius: 14,
                                        backgroundColor: isRoot
                                            ? AppTheme.deepCobalt.withValues(
                                                alpha: 0.12,
                                              )
                                            : Colors.grey[200],
                                        child: Icon(
                                          isRoot
                                              ? Icons.folder_rounded
                                              : Icons
                                                  .subdirectory_arrow_left_rounded,
                                          size: 16,
                                          color: isRoot
                                              ? AppTheme.deepCobalt
                                              : Colors.grey[700],
                                        ),
                                      ),
                                      title: Text(
                                        cat.name,
                                        style: TextStyle(
                                          fontWeight: isSelected || isRoot
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? AppTheme.actionBlue
                                              : AppTheme.deepCobalt,
                                          fontSize: 14,
                                        ),
                                      ),
                                      subtitle: Text(
                                        path,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      trailing: isSelected
                                          ? const Icon(
                                              Icons.check_circle,
                                              color: AppTheme.actionBlue,
                                              size: 20,
                                            )
                                          : (cat.code != null
                                              ? Container(
                                                  padding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[100],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    cat.code!,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                )
                                              : null),
                                      onTap: () {
                                        setState(
                                          () => _selectedCategoryId = cat.id,
                                        );
                                        Navigator.pop(sheetCtx);
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Department Selector Widget
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
                Icon(Icons.domain_outlined, size: 18, color: AppTheme.actionBlue),
                SizedBox(width: 6),
                Text(
                  'القسم التابع له العنصر (Department)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: _showQuickAddDepartmentDialog,
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
          value: validDepartmentId,
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

  // Category Tree Selector Widget
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
                  onPressed: _showCategoryTreePicker,
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
                  onPressed: _showQuickAddCategoryDialog,
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
          value: validCategoryId,
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

  // Section Card Wrapper
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.actionBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.deepCobalt,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  // Usage Status Segment / Chips
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
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getStatusIcon(status),
                    size: 16,
                    color: isSelected
                        ? Colors.white
                        : _getStatusColor(status),
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
              selectedColor: _getStatusColor(status),
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

  IconData _getStatusIcon(ItemUsageStatus status) {
    return switch (status) {
      ItemUsageStatus.newItem => Icons.fiber_new_rounded,
      ItemUsageStatus.second => Icons.restart_alt_rounded,
      ItemUsageStatus.used => Icons.history_rounded,
      ItemUsageStatus.openBox => Icons.inventory_2_outlined,
    };
  }

  Color _getStatusColor(ItemUsageStatus status) {
    return switch (status) {
      ItemUsageStatus.newItem => AppTheme.success,
      ItemUsageStatus.second => AppTheme.warmOrange,
      ItemUsageStatus.used => Colors.blueGrey,
      ItemUsageStatus.openBox => AppTheme.actionBlue,
    };
  }

  // Main Image Input & Preview
  Widget _buildMainImageInput() {
    final hasImage = _mainImageController.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _mainImageController,
          label: 'رابط الصورة الرئيسية (Main Image)',
          icon: Icons.image_outlined,
          hintText: 'https://example.com/main_image.jpg',
          suffixIcon: hasImage
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () =>
                      setState(() => _mainImageController.clear()),
                )
              : null,
          onChanged: (_) => setState(() {}),
        ),
        if (hasImage) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _mainImageController.text.trim(),
                    height: 80,
                    width: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 80,
                      width: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'معاينة الصورة الرئيسية',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'هذه هي الصورة التي ستظهر بشكل بارز في بطاقة العنصر',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Sub-images List & Management
  Widget _buildSubImagesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الصور الإضافية والفرعية (Sub-images) (${_subImages.length})',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            TextButton.icon(
              onPressed: _showAddSubImageDialog,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: const Text('إضافة صورة فرعية'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_subImages.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border, style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 36,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 6),
                Text(
                  'لا توجد صور إضافية بعد',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _subImages.length,
              itemBuilder: (context, index) {
                final imgUrl = _subImages[index];
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          imgUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Delete Button
                    Positioned(
                      top: 4,
                      right: 12,
                      child: InkWell(
                        onTap: () => setState(() => _subImages.removeAt(index)),
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: AppTheme.error,
                          child: Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                    // Set as Main Image Button
                    Positioned(
                      bottom: 4,
                      left: 12,
                      right: 4,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _mainImageController.text = imgUrl;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم تعيين الصورة كصورة رئيسية'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'تعيين رئيسية',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  // Video Input & Preview Link
  Widget _buildVideoInput() {
    final hasVideo = _videoController.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _videoController,
          label: 'رابط الفيديو (Video URL)',
          icon: Icons.videocam_outlined,
          hintText: 'https://youtube.com/watch?v=... أو رابط مباشر لفيديو',
          suffixIcon: hasVideo
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.open_in_new, size: 18),
                      tooltip: 'معاينة / فتح الرابط',
                      onPressed: () async {
                        final uri = Uri.tryParse(_videoController.text.trim());
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تعذر فتح رابط الفيديو'),
                              ),
                            );
                          }
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () =>
                          setState(() => _videoController.clear()),
                    ),
                  ],
                )
              : null,
          onChanged: (_) => setState(() {}),
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

  Widget _buildBarcodeList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'باركودات إضافية',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            TextButton.icon(
              onPressed: _addBarcode,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('إضافة باركود'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.actionBlue,
              ),
            ),
          ],
        ),
        if (_barcodes.isEmpty)
          Text(
            'لا توجد باركودات مضافة',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          )
        else
          Wrap(
            spacing: 8,
            children: _barcodes
                .map(
                  (b) => Chip(
                    label: Text(b, style: const TextStyle(fontSize: 12)),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => setState(() => _barcodes.remove(b)),
                    backgroundColor: Colors.grey[100],
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}
