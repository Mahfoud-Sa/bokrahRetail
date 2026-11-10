import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/features/items/data/entities/category_entity.dart';
import 'package:bokrah_retail/app/features/items/data/entities/item_entity.dart';
import 'package:bokrah_retail/app/features/units/domain/entities/unit_entity.dart';
import 'package:bokrah_retail/app/features/units/domain/usecases/unit_usecases.dart';
import 'package:bokrah_retail/app/features/units/data/datasources/unit_local_datasource.dart';
import 'package:bokrah_retail/app/features/units/data/repositories/unit_repository_impl.dart';
import 'package:bokrah_retail/app/features/items/data/services/categories_service.dart';
import 'package:bokrah_retail/app/features/items/data/services/items_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bokrah_retail/app/features/items/presentation/widgets/barcode_scanner_dialog.dart';
import 'package:flutter/material.dart';
// import flutter/services
import 'package:bokrah_retail/app/core/auth/app_access_guard.dart';

class AddItemPage extends StatefulWidget {
  final ItemEntity? item;
  const AddItemPage({super.key, this.item});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final _formKey = GlobalKey<FormState>();
  final ItemsService _itemsService = ItemsService();
  final CategoriesService _categoriesService = CategoriesService();

  late TextEditingController _nameController;
  late TextEditingController _popularNameController;
  late TextEditingController _companyNameController;
  late TextEditingController _sellPriceController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _quantityController;
  late TextEditingController _colorController;
  late TextEditingController _sizeController;
  late TextEditingController _descriptionController;
  late TextEditingController _qrCodeController;

  List<CategoryEntity> _categories = [];
  int? _selectedCategoryId;
  List<String> _barcodes = [];
  List<String> _images = [];
  String? _baseImage;
  bool _isLoading = false;

  List<UnitEntity> _units = [];

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _popularNameController = TextEditingController(
      text: item?.popularName ?? '',
    );
    _companyNameController = TextEditingController(
      text: item?.companyName ?? '',
    );
    _sellPriceController = TextEditingController(
      text: item?.sellPrice.toString() ?? '',
    );
    _purchasePriceController = TextEditingController(
      text: item?.purchasePrice.toString() ?? '',
    );
    _quantityController = TextEditingController(
      text: item?.quantity.toString() ?? '',
    );
    _colorController = TextEditingController(text: item?.color ?? '');
    _sizeController = TextEditingController(text: item?.size ?? '');
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    _qrCodeController = TextEditingController(text: item?.qrCode ?? '');

    _selectedCategoryId = item?.categoryId;
    _barcodes = List.from(item?.barcodes ?? []);
    _images = List.from(item?.images ?? []);
    _baseImage = item?.baseImage;

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _categoriesService.getAllCategories();
      _categories = categories;

      if (widget.item != null) {
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
    _popularNameController.dispose();
    _companyNameController.dispose();
    _sellPriceController.dispose();
    _purchasePriceController.dispose();
    _quantityController.dispose();
    _colorController.dispose();
    _sizeController.dispose();
    _descriptionController.dispose();
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
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
                                ? const Icon(Icons.star, color: AppTheme.warmOrange)
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

  Future<void> _saveItem() async {
    if (!await AppAccessGuard.requireRestaurant(
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
      popularName: _popularNameController.text.trim().isEmpty
          ? null
          : _popularNameController.text.trim(),
      companyName: _companyNameController.text.trim().isEmpty
          ? null
          : _companyNameController.text.trim(),
      sellPrice: double.tryParse(_sellPriceController.text) ?? 0.0,
      purchasePrice: double.tryParse(_purchasePriceController.text) ?? 0.0,
      quantity: int.tryParse(_quantityController.text) ?? 0,
      color: _colorController.text.trim().isEmpty
          ? null
          : _colorController.text.trim(),
      size: _sizeController.text.trim().isEmpty
          ? null
          : _sizeController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      qrCode: _qrCodeController.text.trim().isEmpty
          ? null
          : _qrCodeController.text.trim(),
      categoryId: _selectedCategoryId,
      barcodes: _barcodes,
      images: _images,
      baseImage: _baseImage,
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
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              )
            else
              TextButton(
                onPressed: _saveItem,
                child: const Text(
                  'حفظ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
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
                _buildSectionTitle('المعلومات الأساسية'),
                _buildTextField(
                  controller: _nameController,
                  label: 'اسم العنصر *',
                  icon: Icons.label,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'يرجى إدخال الاسم' : null,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _popularNameController,
                  label: 'الاسم الشائع',
                  icon: Icons.star_outline,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _companyNameController,
                  label: 'اسم الشركة',
                  icon: Icons.business,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _selectedCategoryId,
                  decoration: _buildInputDecoration('الفئة', Icons.category),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('بدون فئة'),
                    ),
                    ..._categories.map(
                      (c) => DropdownMenuItem<int>(
                        value: c.id,
                        child: Text(c.name),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                ),

                const SizedBox(height: 24),
                _buildSectionTitle('التسعير والوحدات'),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _purchasePriceController,
                        label: 'سعر الشراء',
                        icon: Icons.shopping_cart,
                        keyboardType: const TextInputType.numberWithOptions(
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
                        keyboardType: const TextInputType.numberWithOptions(
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
                        icon: Icons.inventory,
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

                const SizedBox(height: 24),
                _buildSectionTitle('المواصفات والباركود'),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _colorController,
                        label: 'اللون',
                        icon: Icons.palette,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _sizeController,
                        label: 'المقاس',
                        icon: Icons.aspect_ratio,
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

                const SizedBox(height: 24),
                _buildSectionTitle('الصور والوصف'),
                _buildImageSection(),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'الوصف',
                  icon: Icons.description,
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.deepCobalt,
        ),
      ),
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
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

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('صور المنتج', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildAddImageButton(),
              ..._images.map((img) => _buildImageThumbnail(img)),
            ],
          ),
        ),
        if (_images.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'لم يتم اختيار صور',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('اختيار الصور قريباً')));
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            style: BorderStyle.solid,
          ),
        ),
        child: const Icon(Icons.add_a_photo, color: Colors.grey),
      ),
    );
  }

  Widget _buildImageThumbnail(String imgUrl) {
    final isBase = _baseImage == imgUrl;
    return Stack(
      children: [
        Container(
          width: 100,
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: const DecorationImage(
              image: AssetImage(
                'assets/images/placeholder.png',
              ), // Placeholder for now
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 12,
          child: GestureDetector(
            onTap: () => setState(() => _images.remove(imgUrl)),
            child: const CircleAvatar(
              radius: 12,
              backgroundColor: AppTheme.error,
              child: Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
        if (isBase)
          Positioned(
            bottom: 4,
            left: 12,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'أساسية',
                style: TextStyle(color: Colors.white, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

