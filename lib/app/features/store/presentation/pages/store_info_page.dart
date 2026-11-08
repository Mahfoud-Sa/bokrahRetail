import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:bokrah_design_system/bokrah_design_system.dart';
import 'package:bokrah_retail/app/core/auth/app_access_guard.dart';
import '../../data/models/store_entity.dart';
import '../../data/services/store_service.dart';
import '../../../../initialzation_dependencies.dart';
import '../cubits/store_cubit.dart';
import '../cubits/store_state.dart';
import '../widgets/retail_receipt_preview.dart';

class StoreInfoPage extends StatelessWidget {
  final bool isRestaurant;
  const StoreInfoPage({super.key, this.isRestaurant = false});

  @override
  Widget build(BuildContext context) {
    StoreCubit? cubit;
    try {
      cubit = context.read<StoreCubit>();
    } catch (_) {
      if (singelton.isRegistered<StoreCubit>()) {
        cubit = singelton<StoreCubit>();
      }
    }

    if (cubit != null) {
      return _StoreInfoView(isRestaurant: isRestaurant);
    }

    final service = singelton.isRegistered<StoreService>()
        ? singelton<StoreService>()
        : (singelton.isRegistered<RestaurantService>()
            ? singelton<RestaurantService>()
            : (isRestaurant ? RestaurantService() : StoreService()));

    return BlocProvider<StoreCubit>(
      create: (_) => StoreCubit(service: service)..loadStore(),
      child: _StoreInfoView(isRestaurant: isRestaurant),
    );
  }
}

class _StoreInfoView extends StatefulWidget {
  final bool isRestaurant;
  const _StoreInfoView({this.isRestaurant = false});

  @override
  State<_StoreInfoView> createState() => _StoreInfoViewState();
}

class _StoreInfoViewState extends State<_StoreInfoView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  late TextEditingController _nameArController;
  late TextEditingController _nameEnController;
  late TextEditingController _sloganController;
  late TextEditingController _subtitleController;
  late TextEditingController _businessTypeController;
  late TextEditingController _descriptionController;

  late TextEditingController _crController;
  late TextEditingController _taxNumberController;
  late TextEditingController _taxRateController;
  late TextEditingController _currencyController;
  late TextEditingController _warrantyPolicyController;
  late TextEditingController _returnPolicyController;

  late TextEditingController _phoneController;
  late TextEditingController _mobileController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  List<StorePhoneNumberInput> _phoneNumbers = [];

  late TextEditingController _countryController;
  late TextEditingController _cityController;
  late TextEditingController _districtController;
  late TextEditingController _streetController;
  late TextEditingController _buildingController;
  late TextEditingController _postalCodeController;
  late TextEditingController _shortAddressController;
  late TextEditingController _googleMapsUrlController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;

  late TextEditingController _ownerNameController;

  late TextEditingController _headerNoteController;
  late TextEditingController _footerNoteController;
  late TextEditingController _openingTimeController;
  late TextEditingController _closingTimeController;

  bool _isTaxEnabled = true;
  String _selectedCurrency = 'SAR';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initControllers();
  }

  void _initControllers() {
    _nameArController = TextEditingController();
    _nameEnController = TextEditingController();
    _sloganController = TextEditingController();
    _subtitleController = TextEditingController();
    _businessTypeController = TextEditingController();
    _descriptionController = TextEditingController();

    _crController = TextEditingController();
    _taxNumberController = TextEditingController();
    _taxRateController = TextEditingController();
    _currencyController = TextEditingController(text: 'SAR');
    _warrantyPolicyController = TextEditingController();
    _returnPolicyController = TextEditingController();

    _phoneController = TextEditingController();
    _mobileController = TextEditingController();
    _emailController = TextEditingController();
    _websiteController = TextEditingController();

    _countryController = TextEditingController();
    _cityController = TextEditingController();
    _districtController = TextEditingController();
    _streetController = TextEditingController();
    _buildingController = TextEditingController();
    _postalCodeController = TextEditingController();
    _shortAddressController = TextEditingController();
    _googleMapsUrlController = TextEditingController();
    _latitudeController = TextEditingController();
    _longitudeController = TextEditingController();

    _ownerNameController = TextEditingController();

    _headerNoteController = TextEditingController();
    _footerNoteController = TextEditingController();
    _openingTimeController = TextEditingController();
    _closingTimeController = TextEditingController();
  }

  void _populateFromEntity(StoreEntity s) {
    _nameArController.text = s.nameAr;
    _nameEnController.text = s.nameEn;
    _sloganController.text = s.slogan;
    _subtitleController.text = s.subtitle;
    _businessTypeController.text = s.businessType;
    _descriptionController.text = s.description;

    _crController.text = s.commercialRegistration;
    _taxNumberController.text = s.taxNumber;
    _taxRateController.text = s.taxRate.toStringAsFixed(1);
    _currencyController.text = s.currency;
    _selectedCurrency = s.currency.isNotEmpty ? s.currency : 'SAR';
    _isTaxEnabled = s.isTaxEnabled;
    _warrantyPolicyController.text = s.warrantyPolicy;
    _returnPolicyController.text = s.returnPolicy;

    _phoneController.text = s.phoneNumber;
    _mobileController.text = s.mobileNumber;
    _emailController.text = s.email;
    _websiteController.text = s.website;
    _phoneNumbers = List.from(s.phoneNumbers);

    _countryController.text = s.country;
    _cityController.text = s.city;
    _districtController.text = s.district;
    _streetController.text = s.street;
    _buildingController.text = s.buildingNumber;
    _postalCodeController.text = s.postalCode;
    _shortAddressController.text = s.shortAddress;
    _googleMapsUrlController.text = s.googleMapsUrl;
    _latitudeController.text = s.latitude?.toString() ?? '';
    _longitudeController.text = s.longitude?.toString() ?? '';

    _ownerNameController.text = s.ownerName ?? '';

    _headerNoteController.text = s.receiptHeaderNote;
    _footerNoteController.text = s.receiptFooterNote;
    _openingTimeController.text = s.openingTime;
    _closingTimeController.text = s.closingTime;
  }

  StoreEntity _buildCurrentEntity(StoreEntity original) {
    return original.copyWith(
      nameAr: _nameArController.text.trim(),
      nameEn: _nameEnController.text.trim(),
      slogan: _sloganController.text.trim(),
      subtitle: _subtitleController.text.trim(),
      businessType: _businessTypeController.text.trim(),
      description: _descriptionController.text.trim(),
      commercialRegistration: _crController.text.trim(),
      taxNumber: _taxNumberController.text.trim(),
      taxRate: double.tryParse(_taxRateController.text.trim()) ?? 15.0,
      isTaxEnabled: _isTaxEnabled,
      currency: _selectedCurrency,
      warrantyPolicy: _warrantyPolicyController.text.trim(),
      returnPolicy: _returnPolicyController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      mobileNumber: _mobileController.text.trim(),
      email: _emailController.text.trim(),
      website: _websiteController.text.trim(),
      phoneNumbers: _phoneNumbers,
      country: _countryController.text.trim(),
      city: _cityController.text.trim(),
      district: _districtController.text.trim(),
      street: _streetController.text.trim(),
      buildingNumber: _buildingController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
      shortAddress: _shortAddressController.text.trim(),
      googleMapsUrl: _googleMapsUrlController.text.trim(),
      latitude: double.tryParse(_latitudeController.text.trim()),
      longitude: double.tryParse(_longitudeController.text.trim()),
      ownerName: _ownerNameController.text.trim(),
      receiptHeaderNote: _headerNoteController.text.trim(),
      receiptFooterNote: _footerNoteController.text.trim(),
      openingTime: _openingTimeController.text.trim(),
      closingTime: _closingTimeController.text.trim(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameArController.dispose();
    _nameEnController.dispose();
    _sloganController.dispose();
    _subtitleController.dispose();
    _businessTypeController.dispose();
    _descriptionController.dispose();
    _crController.dispose();
    _taxNumberController.dispose();
    _taxRateController.dispose();
    _currencyController.dispose();
    _warrantyPolicyController.dispose();
    _returnPolicyController.dispose();
    _phoneController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _streetController.dispose();
    _buildingController.dispose();
    _postalCodeController.dispose();
    _shortAddressController.dispose();
    _googleMapsUrlController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _ownerNameController.dispose();
    _headerNoteController.dispose();
    _footerNoteController.dispose();
    _openingTimeController.dispose();
    _closingTimeController.dispose();
    super.dispose();
  }

  Future<void> _handleSave(StoreEntity current) async {
    if (!await AppAccessGuard.requireStore(
      context: context,
      returnRoute: '/store-info',
    )) {
      return;
    }
    if (!mounted) return;
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يُرجى التأكد من ملء جميع الحقول المطلوبة بشكل صحيح'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final cubit = context.read<StoreCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final entityToSave = _buildCurrentEntity(current);
    final success = await cubit.updateStore(entityToSave);
    if (!mounted) return;
    if (success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('تم حفظ وتحديث بيانات المتجر بنجاح!'),
            ],
          ),
          backgroundColor: Color(0xFF2E7D64),
        ),
      );
    }
  }

  Future<void> _confirmReset() async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final cubit = context.read<StoreCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Text(isArabic ? 'استعادة الافتراضي' : 'Reset to Defaults'),
          content: Text(
            isArabic
                ? 'هل أنت متأكد من رغبتك في استعادة بيانات المتجر الافتراضية؟ سيتم استبدال البيانات الحالية.'
                : 'Are you sure you want to restore the default store profile? Current changes will be overwritten.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text(isArabic ? 'إلغاء' : 'Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: Text(
                isArabic ? 'استعادة الافتراضي' : 'Reset',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await cubit.resetDefaults();
      setState(() {
        _isInitialized = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return BlocConsumer<StoreCubit, StoreState>(
      listener: (context, state) {
        if (state is StoreLoaded) {
          if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      },
      builder: (context, state) {
        if (state is StoreLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final store = state is StoreLoaded
            ? state.store
            : StoreEntity.defaultStore();

        if (!_isInitialized) {
          _populateFromEntity(store);
          _isInitialized = true;
        }

        final isStaff = store.isStaff;
        final isManager = store.isManager;
        final canEdit = store.canManageSettings; // Owner can manage settings

        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            appBar: AppBar(
              title: Text(isArabic
                  ? (widget.isRestaurant
                      ? 'بيانات وإعدادات المطعم'
                      : 'بيانات وإعدادات المتجر')
                  : (widget.isRestaurant
                      ? 'Restaurant Profile'
                      : 'Store Profile & Settings')),
              centerTitle: false,
              actions: [
                if (canEdit) ...[
                  IconButton(
                    tooltip: isArabic ? 'استعادة الافتراضي' : 'Reset Defaults',
                    icon: const Icon(Icons.refresh_outlined),
                    onPressed: _confirmReset,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: Text(isArabic ? 'حفظ التعديلات' : 'Save Changes'),
                      onPressed: () => _handleSave(store),
                    ),
                  ),
                ] else if (isManager) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Chip(
                      avatar: const Icon(Icons.visibility_outlined, size: 16),
                      label: Text(
                        isArabic ? 'عرض فقط' : 'View Only',
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ],
              bottom: isStaff
                  ? null
                  : TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      tabs: [
                        Tab(
                          icon: const Icon(Icons.storefront_outlined),
                          text: isArabic ? 'الهوية والبيانات' : 'Store Identity',
                        ),
                        Tab(
                          icon: const Icon(Icons.gavel_outlined),
                          text: isArabic ? 'الضريبة والضمان' : 'Tax & Warranty',
                        ),
                        Tab(
                          icon: const Icon(Icons.contact_mail_outlined),
                          text: isArabic ? 'الاتصال والعنوان' : 'Contact & Address',
                        ),
                        Tab(
                          icon: const Icon(Icons.receipt_long_outlined),
                          text: isArabic ? 'الفواتير وساعات العمل' : 'Receipt & Hours',
                        ),
                      ],
                    ),
            ),
            body: isStaff
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 64,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isArabic
                                ? 'إدارة إعدادات المتجر مقيدة'
                                : 'Store Settings Restricted',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            isArabic
                                ? 'حسابك مسجل بدور (موظف - Staff). تعديل الإعدادات والبيانات القانونية والضريبية متاح للمالك والمدير فقط.'
                                : 'Your account has Staff permissions. Modifying store legal and profile settings requires Owner or Manager privileges.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      if (isManager)
                        Container(
                          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  color: Colors.blue, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  isArabic
                                      ? 'وضع العرض فقط: حسابك مسجل بصلاحية (مدير). يمكنك استعراض الإعدادات والبيانات، بينما يتطلب إجراء التعديلات صلاحية (المالك - Owner).'
                                      : 'View-only mode: You have Manager permissions. You can view store configuration, but only the Owner can save changes.',
                                  style: const TextStyle(
                                      fontSize: 12, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: IgnorePointer(
                          ignoring: !canEdit,
                          child: Form(
                            key: _formKey,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildIdentityTab(store, isArabic, theme),
                                _buildTaxAndWarrantyTab(store, isArabic, theme),
                                _buildContactTab(store, isArabic, theme),
                                _buildReceiptAndHoursTab(store, isArabic, theme),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  // --- TAB 1: STORE IDENTITY ---
  Widget _buildIdentityTab(StoreEntity store, bool isArabic, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Banner
              _buildStoreHeroBanner(store, isArabic, theme),
              const SizedBox(height: 24),

              BkCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? 'بيانات المتجر الأساسية' : 'Basic Store Details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameArController,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'اسم المتجر (بالعربية) *' : 'Store Name (Arabic) *',
                          prefixIcon: const Icon(Icons.store),
                        ),
                        validator: (val) {
                          if ((val == null || val.trim().isEmpty) &&
                              _nameEnController.text.trim().isEmpty) {
                            return isArabic
                                ? 'يُرجى إدخال اسم المتجر بالعربية أو بالإنجليزية'
                                : 'Please enter Arabic or English store name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _nameEnController,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'اسم المتجر (بالإنجليزية) *' : 'Store Name (English) *',
                          prefixIcon: const Icon(Icons.store_mall_directory_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _subtitleController,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'العنوان الفرعي للمتجر' : 'Store Subtitle',
                          prefixIcon: const Icon(Icons.subtitles_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _sloganController,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'شعار المتجر اللفظي (Slogan)' : 'Store Slogan',
                          prefixIcon: const Icon(Icons.format_quote_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _businessTypeController,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'نوع النشاط / التخصص' : 'Business Category / Type',
                          prefixIcon: const Icon(Icons.category_outlined),
                          hintText: isArabic
                              ? 'مثال: إلكترونيات وأجهزة ذكية، هواتف، حواسيب'
                              : 'e.g. Consumer Electronics & Smartphones',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _ownerNameController,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'اسم مالك المتجر / المدير المسؤول' : 'Owner / Manager Name',
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'نبذة عن المتجر (Description)' : 'About Store (Description)',
                          prefixIcon: const Icon(Icons.description_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: isArabic ? Alignment.centerLeft : Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () {
                    try {
                      context.go('/home');
                    } catch (_) {}
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(isArabic ? 'المتابعة للرئيسية' : 'Go to Dashboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreHeroBanner(StoreEntity store, bool isArabic, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: theme.colorScheme.primary,
            child: const Icon(Icons.storefront, size: 36, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.nameAr.isNotEmpty ? store.nameAr : (isArabic ? 'متجر بكرة' : 'Bokrah Retail Store'),
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (store.nameEn.isNotEmpty)
                  Text(
                    store.nameEn,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                  ),
                if (store.subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      store.subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    if (store.ownerName != null && store.ownerName!.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_pin, size: 14, color: Colors.grey.shade700),
                          const SizedBox(width: 4),
                          Text('المالك: ${store.ownerName}', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    if (store.googleMapsUrl.isNotEmpty || store.latitude != null)
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.green),
                          SizedBox(width: 4),
                          Text('موقع الخريطة متاح', style: TextStyle(fontSize: 12, color: Colors.green)),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: TAX & WARRANTY ---
  Widget _buildTaxAndWarrantyTab(StoreEntity store, bool isArabic, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BkCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? 'البيانات الضريبية والتجارية' : 'Tax & Commercial Details',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _crController,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'رقم السجل التجاري (CR)' : 'Commercial Registration (CR)',
                          prefixIcon: const Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _taxNumberController,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'الرقم الضريبي (VAT Number)' : 'VAT Number',
                          prefixIcon: const Icon(Icons.pin_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _taxRateController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: isArabic ? 'نسبة الضريبة (%)' : 'VAT Rate (%)',
                                prefixIcon: const Icon(Icons.percent_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedCurrency,
                              decoration: InputDecoration(
                                labelText: isArabic ? 'العملة الأساسية' : 'Primary Currency',
                                prefixIcon: const Icon(Icons.currency_exchange),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'SAR', child: Text('ريال سعودي (SAR)')),
                                DropdownMenuItem(value: 'JOD', child: Text('دينار أردني (JOD)')),
                                DropdownMenuItem(value: 'AED', child: Text('درهم إماراتي (AED)')),
                                DropdownMenuItem(value: 'USD', child: Text('دولار أمريكي (USD)')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _selectedCurrency = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(isArabic ? 'تفعيل حساب الضريبة في الفواتير' : 'Enable VAT in Invoices'),
                        subtitle: Text(isArabic ? 'إظهار نسبة ومبلغ ضريبة القيمة المضافة في الفواتير' : 'Show VAT calculation on POS receipts'),
                        value: _isTaxEnabled,
                        onChanged: (v) => setState(() => _isTaxEnabled = v),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Warranty & Return Policies
              BkCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_outlined, color: Colors.blueGrey),
                          const SizedBox(width: 8),
                          Text(
                            isArabic ? 'سياسات الضمان والاسترجاع (خاص بمتاجر الإلكترونيات والتجزئة)' : 'Warranty & Return Policy (Retail & Electronics)',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _warrantyPolicyController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'سياسة الضمان على الأجهزة والقطع' : 'Warranty Policy',
                          prefixIcon: const Icon(Icons.security_outlined),
                          hintText: isArabic ? 'مثال: ضمان الوكيل سنتين على كافة الأجهزة الذكية' : 'e.g. 2-year authorized dealer warranty',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _returnPolicyController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'سياسة الاسترجاع والاستبدال' : 'Return & Exchange Policy',
                          prefixIcon: const Icon(Icons.assignment_return_outlined),
                          hintText: isArabic ? 'مثال: استرجاع خلال 7 أيام واستبدال خلال 14 يوماً مع الفاتورة الأصلية' : 'e.g. 7 days return, 14 days exchange',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: isArabic ? Alignment.centerLeft : Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () {
                    try {
                      context.go('/home');
                    } catch (_) {}
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(isArabic ? 'المتابعة للرئيسية' : 'Go to Dashboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- TAB 3: CONTACT & ADDRESS ---
  Widget _buildContactTab(StoreEntity store, bool isArabic, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BkCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? 'العنوان والموقع الجغرافي' : 'Store Address & Location',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _countryController,
                              decoration: InputDecoration(
                                labelText: isArabic ? 'الدولة' : 'Country',
                                prefixIcon: const Icon(Icons.public),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              decoration: InputDecoration(
                                labelText: isArabic ? 'المدينة' : 'City',
                                prefixIcon: const Icon(Icons.location_city),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _districtController,
                              decoration: InputDecoration(
                                labelText: isArabic ? 'الحي' : 'District',
                                prefixIcon: const Icon(Icons.map_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _streetController,
                              decoration: InputDecoration(
                                labelText: isArabic ? 'الشارع' : 'Street',
                                prefixIcon: const Icon(Icons.signpost_outlined),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _buildingController,
                              decoration: InputDecoration(
                                labelText: isArabic ? 'رقم المبنى' : 'Building No.',
                                prefixIcon: const Icon(Icons.business_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _postalCodeController,
                              decoration: InputDecoration(
                                labelText: isArabic ? 'الرمز البريدي' : 'Postal Code',
                                prefixIcon: const Icon(Icons.markunread_mailbox_outlined),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _googleMapsUrlController,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'رابط خرائط جوجل (Google Maps URL)' : 'Google Maps URL',
                          prefixIcon: const Icon(Icons.pin_drop_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latitudeController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: isArabic ? 'خط العرض (Latitude)' : 'Latitude',
                                prefixIcon: const Icon(Icons.my_location),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _longitudeController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: isArabic ? 'خط الطول (Longitude)' : 'Longitude',
                                prefixIcon: const Icon(Icons.location_searching),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Contacts
              BkCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? 'بيانات التواصل الإلكتروني' : 'Contact & Online Presence',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'هاتف المتجر الأساسي' : 'Primary Phone',
                          prefixIcon: const Icon(Icons.phone),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _mobileController,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'الجوال / الواتساب' : 'Mobile / WhatsApp',
                          prefixIcon: const Icon(Icons.smartphone),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'البريد الإلكتروني الرسمي' : 'Email Address',
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _websiteController,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'الموقع الإلكتروني أو المتجر الإلكتروني' : 'Website or E-Commerce Store',
                          prefixIcon: const Icon(Icons.language),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isArabic ? 'أرقام تواصل إضافية' : 'Additional Phone Numbers',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      for (final p in _phoneNumbers)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Chip(label: Text(p.type)),
                              const SizedBox(width: 8),
                              Text(p.number, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: isArabic ? Alignment.centerLeft : Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () {
                    try {
                      context.go('/home');
                    } catch (_) {}
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(isArabic ? 'المتابعة للرئيسية' : 'Go to Dashboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- TAB 4: RECEIPTS & HOURS ---
  Widget _buildReceiptAndHoursTab(StoreEntity store, bool isArabic, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form Column
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    BkCard(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isArabic ? 'إعدادات نصوص الفاتورة' : 'Receipt Header & Footer',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _headerNoteController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                labelText: isArabic ? 'ترويسة الفاتورة (Header Note)' : 'Receipt Header Note',
                                prefixIcon: const Icon(Icons.title),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _footerNoteController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                labelText: isArabic ? 'تذييل الفاتورة (Footer Note)' : 'Receipt Footer Note',
                                prefixIcon: const Icon(Icons.notes),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    BkCard(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isArabic ? 'ساعات العمل' : 'Business Hours',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _openingTimeController,
                                    decoration: InputDecoration(
                                      labelText: isArabic ? 'وقت الفتح' : 'Opening Time',
                                      prefixIcon: const Icon(Icons.access_time),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: TextFormField(
                                    controller: _closingTimeController,
                                    decoration: InputDecoration(
                                      labelText: isArabic ? 'وقت الإغلاق' : 'Closing Time',
                                      prefixIcon: const Icon(Icons.timelapse),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),

              // Live Receipt Preview
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Text(
                      isArabic ? 'معاينة مباشرة للفاتورة' : 'Live Receipt Preview',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    RetailReceiptPreview(
                      store: _buildCurrentEntity(store),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Backward compatibility alias class
class RestaurantInfoPage extends StoreInfoPage {
  const RestaurantInfoPage({super.key, super.isRestaurant = true});
}
