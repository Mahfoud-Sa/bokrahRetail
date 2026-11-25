import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/core/auth/app_access_guard.dart';
import 'package:bokrah_retail/app/core/widgets/widgets.dart';
import 'package:bokrah_retail/app/features/companies/domain/entities/company_entity.dart';
import 'package:bokrah_retail/app/features/companies/presentation/bloc/companies_cubit.dart';
import 'package:bokrah_retail/app/features/companies/presentation/company_access.dart';

class UpdateCompanyPage extends StatefulWidget {
  final CompanyEntity company;

  const UpdateCompanyPage({super.key, required this.company});

  @override
  State<UpdateCompanyPage> createState() => _UpdateCompanyPageState();
}

class _UpdateCompanyPageState extends State<UpdateCompanyPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _arabicNameController;
  late final TextEditingController _englishNameController;
  late final TextEditingController _codeController;
  late final TextEditingController _imageController;
  late final TextEditingController _brandInputController;
  late final TextEditingController _websiteController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _descriptionController;

  late List<String> _brands;

  // Preset popular logos for quick admin selection
  static const List<Map<String, String>> _presetLogos = [
    {
      'name': 'Apple',
      'nameAr': 'أبل',
      'nameEn': 'Apple Inc.',
      'code': 'AAPL',
      'url':
          'https://upload.wikimedia.org/wikipedia/commons/f/fa/Apple_logo_black.svg',
      'defaultBrands': 'iPhone, iPad, Mac, AirPods, Apple Watch',
    },
    {
      'name': 'Samsung',
      'nameAr': 'سامسونج',
      'nameEn': 'Samsung Electronics',
      'code': 'SAMS',
      'url':
          'https://upload.wikimedia.org/wikipedia/commons/2/24/Samsung_Logo.svg',
      'defaultBrands': 'Galaxy, Odyssey, Neo QLED, SmartThings',
    },
    {
      'name': 'Sony',
      'nameAr': 'سوني',
      'nameEn': 'Sony Corporation',
      'code': 'SONY',
      'url':
          'https://upload.wikimedia.org/wikipedia/commons/c/ca/Sony_logo.svg',
      'defaultBrands': 'PlayStation, Bravia, Xperia, Alpha',
    },
    {
      'name': 'Almarai',
      'nameAr': 'المراعي',
      'nameEn': 'Almarai Company',
      'code': 'ALMR',
      'url':
          'https://upload.wikimedia.org/wikipedia/en/thumb/d/d4/Almarai_logo.svg/330px-Almarai_logo.svg.png',
      'defaultBrands': 'المراعي, لوزين, سفن دايز, نيورالاك',
    },
    {
      'name': 'Unilever',
      'nameAr': 'يونيليفر',
      'nameEn': 'Unilever',
      'code': 'ULVR',
      'url':
          'https://upload.wikimedia.org/wikipedia/en/thumb/8/87/Unilever.svg/330px-Unilever.svg.png',
      'defaultBrands': 'Dove, Lipton, Sunsilk, Lifebuoy, Knorr',
    },
    {
      'name': 'Dell',
      'nameAr': 'ديل',
      'nameEn': 'Dell Technologies',
      'code': 'DELL',
      'url':
          'https://upload.wikimedia.org/wikipedia/commons/4/48/Dell_Logo.svg',
      'defaultBrands': 'Alienware, Latitude, XPS, Inspiron',
    },
    {
      'name': 'LG',
      'nameAr': 'إل جي',
      'nameEn': 'LG Electronics',
      'code': 'LG',
      'url':
          'https://upload.wikimedia.org/wikipedia/commons/b/bf/LG_logo_%282015%29.svg',
      'defaultBrands': 'OLED, ThinQ, Gram, UltraGear',
    },
    {
      'name': 'Nestle',
      'nameAr': 'نستله',
      'nameEn': 'Nestlé',
      'code': 'NSTL',
      'url':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d6/Nestl%C3%A9_textlogo.svg/320px-Nestl%C3%A9_textlogo.svg.png',
      'defaultBrands': 'Nescafé, KitKat, Nespresso, Maggi',
    },
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.company;
    _nameController = TextEditingController(text: c.name);
    _arabicNameController = TextEditingController(text: c.arabicName);
    _englishNameController = TextEditingController(text: c.englishName);
    _codeController = TextEditingController(text: c.code ?? '');
    _imageController = TextEditingController(text: c.image ?? '');
    _brandInputController = TextEditingController();
    _websiteController = TextEditingController(text: c.website ?? '');
    _emailController = TextEditingController(text: c.email ?? '');
    _phoneController = TextEditingController(text: c.phone ?? '');
    _addressController = TextEditingController(text: c.address ?? '');
    _descriptionController = TextEditingController(text: c.description ?? '');
    _brands = List<String>.from(c.brands);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _arabicNameController.dispose();
    _englishNameController.dispose();
    _codeController.dispose();
    _imageController.dispose();
    _brandInputController.dispose();
    _websiteController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addBrand() {
    final text = _brandInputController.text.trim();
    if (text.isEmpty) return;
    if (!_brands.contains(text)) {
      setState(() {
        _brands.add(text);
        _brandInputController.clear();
      });
    } else {
      _brandInputController.clear();
    }
  }

  void _removeBrand(String brand) {
    setState(() {
      _brands.remove(brand);
    });
  }

  void _applyPreset(Map<String, String> preset) {
    setState(() {
      _imageController.text = preset['url'] ?? '';
      if (_arabicNameController.text.trim().isEmpty &&
          preset['nameAr'] != null) {
        _arabicNameController.text = preset['nameAr']!;
      }
      if (_englishNameController.text.trim().isEmpty &&
          preset['nameEn'] != null) {
        _englishNameController.text = preset['nameEn']!;
      }
      if (_nameController.text.trim().isEmpty && preset['name'] != null) {
        _nameController.text = preset['name']!;
      }
      if (_codeController.text.trim().isEmpty && preset['code'] != null) {
        _codeController.text = preset['code']!;
      }
    });
  }

  Future<void> _submit() async {
    if (!await AppAccessGuard.requireStore(
      context: context,
      returnRoute: '/update-company',
    )) {
      return;
    }
    if (!mounted) return;

    if (!await CompanyAccess.requireManage(context)) return;
    if (!mounted) return;

    if (!_formKey.currentState!.validate()) return;

    final pendingBrand = _brandInputController.text.trim();
    if (pendingBrand.isNotEmpty && !_brands.contains(pendingBrand)) {
      _brands.add(pendingBrand);
    }

    final arName = _arabicNameController.text.trim();
    final enName = _englishNameController.text.trim();
    final customName = _nameController.text.trim();

    final effectiveName = customName.isNotEmpty
        ? customName
        : (enName.isNotEmpty ? enName : arName);

    final image = _imageController.text.trim();
    final code = _codeController.text.trim();
    final description = _descriptionController.text.trim();
    final website = _websiteController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    // Build a fresh entity instead of copyWith: copyWith treats null as
    // "keep existing", so cleared optional fields would never be removed.
    final updatedCompany = CompanyEntity(
      id: widget.company.id,
      name: effectiveName,
      arabicName: arName,
      englishName: enName,
      brands: List<String>.from(_brands),
      image: image.isEmpty ? null : image,
      code: code.isEmpty ? null : code.toUpperCase(),
      description: description.isEmpty ? null : description,
      website: website.isEmpty ? null : website,
      email: email.isEmpty ? null : email,
      phone: phone.isEmpty ? null : phone,
      address: address.isEmpty ? null : address,
      createdAt: widget.company.createdAt,
      updatedAt: DateTime.now(),
    );

    final success = await context.read<CompaniesCubit>().updateCompany(
      updatedCompany,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث بيانات الشركة بنجاح'),
            backgroundColor: AppTheme.success,
          ),
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        } else {
          context.go('/companies');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء تحديث بيانات الشركة'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.select<CompaniesCubit, bool>(
      (cubit) => cubit.state.isSaving,
    );
    final title = widget.company.arabicName.isNotEmpty
        ? widget.company.arabicName
        : widget.company.name;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.mainBackground,
        appBar: AppBar(
          title: Text('تعديل بيانات الشركة: $title'),
          backgroundColor: AppTheme.deepCobalt,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/companies');
              }
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card 1: Names & Identity
                    FormSectionCard(
                      title: 'بيانات الشركة والأسماء (مطلوبة)',
                      icon: Icons.badge_outlined,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _arabicNameController,
                                decoration: const InputDecoration(
                                  labelText: 'الاسم بالعربية *',
                                  hintText: 'مثال: أبل، سامسونج، المراعي',
                                  prefixIcon: Icon(Icons.translate),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'يرجى إدخال اسم الشركة بالعربية'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _englishNameController,
                                decoration: const InputDecoration(
                                  labelText: 'الاسم بالإنجليزية *',
                                  hintText:
                                      'e.g. Apple Inc., Samsung Electronics',
                                  prefixIcon: Icon(Icons.language),
                                ),
                                textDirection: TextDirection.ltr,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'يرجى إدخال اسم الشركة بالإنجليزية'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'الاسم التجاري المختصر (اختياري)',
                                  hintText:
                                      'يترك فارغاً لاعتماد الاسم بالإنجليزية أو العربية',
                                  prefixIcon: Icon(Icons.storefront_outlined),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _codeController,
                                decoration: const InputDecoration(
                                  labelText: 'كود الشركة (اختياري)',
                                  hintText: 'مثال: AAPL',
                                  prefixIcon: Icon(Icons.tag),
                                ),
                                textCapitalization:
                                    TextCapitalization.characters,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Card 2: Company Logo & Presets
                    FormSectionCard(
                      title: 'شعار الشركة (Company Logo / Image)',
                      icon: Icons.image_outlined,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'شعارات جاهزة سريعة:',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.secondaryText,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: _presetLogos.map((preset) {
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: ActionChip(
                                        avatar: const Icon(
                                          Icons.auto_awesome,
                                          size: 14,
                                          color: AppTheme.actionBlue,
                                        ),
                                        label: Text(
                                          preset['name']!,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        backgroundColor: AppTheme.subtleSurface,
                                        onPressed: () => _applyPreset(preset),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _imageController,
                              builder: (context, value, _) {
                                final url = value.text.trim();
                                return Container(
                                  width: 84,
                                  height: 84,
                                  decoration: BoxDecoration(
                                    color: AppTheme.subtleSurface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.border),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: url.isNotEmpty
                                      ? Image.network(
                                          url,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              const Center(
                                                child: Icon(
                                                  Icons.broken_image,
                                                  color: AppTheme.secondaryText,
                                                  size: 28,
                                                ),
                                              ),
                                        )
                                      : const Center(
                                          child: Icon(
                                            Icons.business,
                                            color: AppTheme.secondaryText,
                                            size: 36,
                                          ),
                                        ),
                                );
                              },
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextFormField(
                                    controller: _imageController,
                                    decoration: InputDecoration(
                                      labelText:
                                          'رابط صورة / شعار الشركة (URL)',
                                      hintText: 'https://example.com/logo.png',
                                      prefixIcon: const Icon(Icons.link),
                                      suffixIcon:
                                          ValueListenableBuilder<
                                            TextEditingValue
                                          >(
                                            valueListenable: _imageController,
                                            builder: (context, value, _) {
                                              return value.text.isNotEmpty
                                                  ? IconButton(
                                                      icon: const Icon(
                                                        Icons.clear,
                                                        size: 18,
                                                      ),
                                                      onPressed: () =>
                                                          _imageController
                                                              .clear(),
                                                    )
                                                  : const SizedBox.shrink();
                                            },
                                          ),
                                    ),
                                    textDirection: TextDirection.ltr,
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'أدخل رابط صورة الشعار أو اختر من الشعارات الجاهزة أعلاه',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Card 3: Brands Manager
                    FormSectionCard(
                      title: 'العلامات التجارية التابعة للشركة (Brands)',
                      icon: Icons.branding_watermark_outlined,
                      children: [
                        const Text(
                          'أضف أو عدل العلامات التجارية المنتجة أو الموزعة بواسطة هذه الشركة',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _brandInputController,
                                decoration: const InputDecoration(
                                  labelText: 'اسم العلامة التجارية',
                                  hintText:
                                      'اكتب اسم العلامة واضغط إضافة أو Enter...',
                                  prefixIcon: Icon(Icons.bookmark_border),
                                ),
                                onSubmitted: (_) => _addBrand(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            FilledButton.icon(
                              onPressed: _addBrand,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('إضافة علامة'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.actionBlue,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (_brands.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.paleOrange.withValues(
                                alpha: 0.35,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.warmOrange.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _brands.map((brand) {
                                return Chip(
                                  avatar: const CircleAvatar(
                                    backgroundColor: AppTheme.actionBlue,
                                    radius: 10,
                                    child: Icon(
                                      Icons.verified,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                  label: Text(
                                    brand,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  backgroundColor: Colors.white,
                                  deleteIcon: const Icon(Icons.close, size: 16),
                                  deleteIconColor: AppTheme.error,
                                  onDeleted: () => _removeBrand(brand),
                                  side: BorderSide(
                                    color: AppTheme.border.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.subtleSurface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: AppTheme.secondaryText,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'لا توجد علامات تجارية مسجلة. أضف علامة تجارية جديدة للشركة.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Card 4: Contact & Location
                    FormSectionCard(
                      title: 'بيانات التواصل والمقر (اختياري)',
                      icon: Icons.contact_mail_outlined,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _websiteController,
                                decoration: const InputDecoration(
                                  labelText: 'الموقع الإلكتروني',
                                  hintText: 'https://www.example.com',
                                  prefixIcon: Icon(Icons.public),
                                ),
                                textDirection: TextDirection.ltr,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'البريد الإلكتروني',
                                  hintText: 'info@example.com',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                textDirection: TextDirection.ltr,
                                keyboardType: TextInputType.emailAddress,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                decoration: const InputDecoration(
                                  labelText: 'رقم الهاتف',
                                  hintText: '+966 ...',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                ),
                                textDirection: TextDirection.ltr,
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _addressController,
                                decoration: const InputDecoration(
                                  labelText: 'العنوان / بلد المنشأ',
                                  hintText:
                                      'مثال: الرياض، المملكة العربية السعودية',
                                  prefixIcon: Icon(Icons.location_on_outlined),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'نبذة عن الشركة / ملاحظات',
                            hintText: 'وصف لأنشطة الشركة ومجال عملها...',
                            prefixIcon: Icon(Icons.notes_outlined),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: isSaving
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                          ),
                          child: const Text('إلغاء'),
                        ),
                        const SizedBox(width: 14),
                        FilledButton.icon(
                          onPressed: isSaving ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.actionBlue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 14,
                            ),
                          ),
                          icon: isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check, size: 18),
                          label: const Text('حفظ التعديلات'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
