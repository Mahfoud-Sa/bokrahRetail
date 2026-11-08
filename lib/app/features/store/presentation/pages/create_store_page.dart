import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:bokrah_design_system/bokrah_design_system.dart';
import '../../../../initialzation_dependencies.dart';
import '../../../auth/data/datasources/auth_token_storage.dart';
import '../../../settings/presentation/cubits/settings_cubit.dart';
import '../../data/models/store_dto.dart';
import '../../data/services/store_api_service.dart';
import '../cubits/create_store_cubit.dart';
import '../cubits/create_store_state.dart';
import '../cubits/store_cubit.dart';

class CreateStorePage extends StatelessWidget {
  final StoreApiService? apiService;
  final String? returnRoute;
  final bool isRestaurant;

  const CreateStorePage({
    super.key,
    this.apiService,
    this.returnRoute,
    this.isRestaurant = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveApiService = apiService ??
        (singelton.isRegistered<StoreApiService>()
            ? singelton<StoreApiService>()
            : MockStoreApiService(
                tokenStorage: singelton.isRegistered<AuthTokenStorage>()
                    ? singelton<AuthTokenStorage>()
                    : InMemoryAuthTokenStorage(),
              ));

    final bool effectivelyRestaurant =
        isRestaurant || effectiveApiService is MockRestaurantApiService;

    StoreCubit? storeCubit;
    try {
      storeCubit = context.read<StoreCubit>();
    } catch (_) {
      if (singelton.isRegistered<StoreCubit>()) {
        storeCubit = singelton<StoreCubit>();
      }
    }

    return BlocProvider(
      create: (context) => CreateStoreCubit(
        apiService: effectiveApiService,
        storeCubit: storeCubit,
      ),
      child: _CreateStoreView(
        returnRoute: returnRoute,
        isRestaurant: effectivelyRestaurant,
      ),
    );
  }
}

class _CreateStoreView extends StatefulWidget {
  final String? returnRoute;
  final bool isRestaurant;

  const _CreateStoreView({
    this.returnRoute,
    this.isRestaurant = false,
  });

  @override
  State<_CreateStoreView> createState() => _CreateStoreViewState();
}

class _CreateStoreViewState extends State<_CreateStoreView> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _nameArController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _sloganController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _businessTypeController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCurrencyCode = 'JOD';

  final _addressController = TextEditingController();
  final _googleMapsUrlController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  final _websiteController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _commercialRegistrationController = TextEditingController();
  final _taxNumberController = TextEditingController();
  final _warrantyPolicyController = TextEditingController();
  final _returnPolicyController = TextEditingController();

  final List<StorePhoneNumberInput> _dynamicPhoneNumbers = [];

  static const List<String> _phoneTypes = [
    'Mobile',
    'Landline',
    'Sales',
    'WhatsApp',
    'Support',
  ];

  @override
  void initState() {
    super.initState();
    _dynamicPhoneNumbers.add(
      const StorePhoneNumberInput(number: '', type: 'Mobile'),
    );
  }

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    _sloganController.dispose();
    _subtitleController.dispose();
    _businessTypeController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _googleMapsUrlController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _websiteController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _commercialRegistrationController.dispose();
    _taxNumberController.dispose();
    _warrantyPolicyController.dispose();
    _returnPolicyController.dispose();
    super.dispose();
  }

  void _addPhoneNumberField() {
    setState(() {
      _dynamicPhoneNumbers.add(
        const StorePhoneNumberInput(number: '', type: 'Mobile'),
      );
    });
  }

  void _removePhoneNumberField(int index) {
    setState(() {
      _dynamicPhoneNumbers.removeAt(index);
    });
  }

  void _updatePhoneNumber(int index, String number) {
    setState(() {
      _dynamicPhoneNumbers[index] =
          _dynamicPhoneNumbers[index].copyWith(number: number);
    });
  }

  void _updatePhoneType(int index, String type) {
    setState(() {
      _dynamicPhoneNumbers[index] =
          _dynamicPhoneNumbers[index].copyWith(type: type);
    });
  }

  Future<void> _submitForm(bool isArabic) async {
    final cubit = context.read<CreateStoreCubit>();
    final isRestaurant = widget.isRestaurant;

    final nameAr = _nameArController.text.trim();
    final nameEn = _nameEnController.text.trim();

    if (nameAr.isEmpty && nameEn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? (isRestaurant
                    ? 'اسم المطعم (بالعربية أو الإنجليزية) مطلوب.'
                    : 'اسم المتجر (بالعربية أو الإنجليزية) مطلوب.')
                : (isRestaurant
                    ? 'Restaurant name (or Arabic/English name) is required.'
                    : 'Store name (or Arabic/English name) is required.'),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }

    final validPhoneNumbers = _dynamicPhoneNumbers
        .where((p) => p.number.trim().isNotEmpty)
        .map((p) => p.copyWith(number: p.number.trim()))
        .toList();

    final request = CreateStoreRequest(
      name: nameAr.isNotEmpty ? nameAr : nameEn,
      nameAr: nameAr.isNotEmpty ? nameAr : null,
      nameEn: nameEn.isNotEmpty ? nameEn : null,
      slogan: _sloganController.text.trim().isNotEmpty
          ? _sloganController.text.trim()
          : null,
      subtitle: _subtitleController.text.trim().isNotEmpty
          ? _subtitleController.text.trim()
          : null,
      businessType: _businessTypeController.text.trim().isNotEmpty
          ? _businessTypeController.text.trim()
          : 'إلكترونيات وأجهزة ذكية',
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      websiteUrl: _websiteController.text.trim().isNotEmpty
          ? _websiteController.text.trim()
          : null,
      phoneNumber: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      phone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      phoneNumbers: validPhoneNumbers.isNotEmpty ? validPhoneNumbers : null,
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
      address: _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : null,
      currencyCode: _selectedCurrencyCode,
      isActive: true,
      googleMapsUrl: _googleMapsUrlController.text.trim().isNotEmpty
          ? _googleMapsUrlController.text.trim()
          : null,
      latitude: double.tryParse(_latitudeController.text.trim()),
      longitude: double.tryParse(_longitudeController.text.trim()),
      commercialRegistration:
          _commercialRegistrationController.text.trim().isNotEmpty
              ? _commercialRegistrationController.text.trim()
              : null,
      taxNumber: _taxNumberController.text.trim().isNotEmpty
          ? _taxNumberController.text.trim()
          : null,
      warrantyPolicy: _warrantyPolicyController.text.trim().isNotEmpty
          ? _warrantyPolicyController.text.trim()
          : null,
      returnPolicy: _returnPolicyController.text.trim().isNotEmpty
          ? _returnPolicyController.text.trim()
          : null,
    );

    final success = await cubit.submit(request);
    if (success && mounted) {
      final successMsg = isArabic
          ? (isRestaurant
              ? 'تمت إضافة بيانات مطعمك بنجاح. يمكنك الآن متابعة إدخال بيانات أعمالك واستخدام الميزات المتعلقة بالمطعم.'
              : 'تمت إضافة بيانات متجرك بنجاح. يمكنك الآن متابعة إدارة المخزون والمبيعات وكافة ميزات التجزئة.')
          : (isRestaurant
              ? 'Your restaurant details have been added successfully.'
              : 'Your store details have been added successfully. You can now continue managing your store operations.');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  successMsg,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D64),
          duration: const Duration(seconds: 4),
        ),
      );

      if (widget.returnRoute != null && widget.returnRoute!.isNotEmpty) {
        try {
          context.go(widget.returnRoute!);
          return;
        } catch (_) {}
      }

      if (isRestaurant) {
        try {
          context.go('/restaurant/dashboard');
          return;
        } catch (_) {}
      }

      try {
        context.go('/store/dashboard');
        return;
      } catch (_) {}

      try {
        context.go('/home');
        return;
      } catch (_) {}

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
        return;
      }
    }
  }

  void _showAlreadyRegisteredDialog(bool isArabic) {
    final isRestaurant = widget.isRestaurant;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.amber),
            const SizedBox(width: 8),
            Text(isArabic
                ? (isRestaurant ? 'مطعم مسجل بالفعل' : 'متجر مسجل بالفعل')
                : (isRestaurant ? 'Already Registered' : 'Store Already Registered')),
          ],
        ),
        content: Text(
          isArabic
              ? (isRestaurant
                  ? 'لديك مطعم مسجل بالفعل. يمكن لمالك المطعم تسجيل مطعم واحد فقط.'
                  : 'لديك متجر مسجل بالفعل. يمكن لمالك المتجر تسجيل متجر رئيسي واحد.')
              : (isRestaurant
                  ? 'You already have a registered restaurant. A restaurant owner can only add one restaurant.'
                  : 'You already have a registered store. A store owner can only add one store.'),
        ),
        actions: [
          ElevatedButton(
            key: const ValueKey('dialog_navigate_dashboard_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D64),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              if (isRestaurant) {
                try {
                  context.go('/restaurant/dashboard');
                  return;
                } catch (_) {}
              }
              try {
                context.go('/store/dashboard');
              } catch (_) {
                try {
                  context.go('/store-info');
                } catch (_) {}
              }
            },
            child: Text(
              isArabic
                  ? (isRestaurant ? 'الانتقال إلى لوحة المطعم' : 'الانتقال إلى لوحة المتجر')
                  : (isRestaurant ? 'Go to Restaurant Dashboard' : 'Go to Store Dashboard'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isArabic = true;
    try {
      isArabic =
          context.watch<SettingsCubit>().state.locale.languageCode == 'ar';
    } catch (_) {}

    return BlocConsumer<CreateStoreCubit, CreateStoreState>(
      listener: (context, state) {
        if (state.isUnauthorized) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic
                    ? 'انتهت الجلسة أو يلزم تسجيل الدخول لإضافة متجر.'
                    : 'Session expired or login required.',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        } else if (state.isForbidden) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic
                    ? 'غير مصرح لك بإضافة متجر. هذه الميزة مخصصة للمسؤولين والمالكين.'
                    : 'Forbidden: Admin or Store Owner role required.',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        } else if (state.isAlreadyHasStore) {
          _showAlreadyRegisteredDialog(isArabic);
        }
      },
      builder: (context, state) {
        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            appBar: AppBar(
              title: Text(isArabic ? 'إضافة متجر جديد' : 'Create New Store'),
              centerTitle: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (widget.returnRoute != null &&
                      widget.returnRoute!.isNotEmpty) {
                    try {
                      context.go(widget.returnRoute!);
                      return;
                    } catch (_) {}
                  }
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go('/home');
                  }
                },
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Error Cards if present
                        if (state.isUnauthorized)
                          _buildErrorCard(
                            key: const ValueKey('unauthorized_error_card'),
                            title: isArabic
                                ? 'تسجيل الدخول مطلوب'
                                : 'Authentication Required',
                            message: isArabic
                                ? 'يجب تسجيل الدخول بحساب مسؤول أو مالك متجر للمتابعة.'
                                : 'You must be signed in with an authorized account to add a store.',
                            actionButton: ElevatedButton(
                              key: const ValueKey('login_redirect_button'),
                              onPressed: () => context.go('/login'),
                              child: Text(isArabic ? 'تسجيل الدخول' : 'Sign In'),
                            ),
                            theme: theme,
                          ),

                        if (state.isForbidden)
                          _buildErrorCard(
                            key: const ValueKey('forbidden_error_card'),
                            title: isArabic ? 'غير مصرح بإضافة متجر' : 'Access Restricted',
                            message: isArabic
                                ? 'معذرة، إضافة متجر مقتصرة على المسؤول ومالك المتجر فقط.'
                                : 'Only System Administrators and Store Owners are permitted to create a store.',
                            actionButton: OutlinedButton(
                              onPressed: () => context.go('/home'),
                              child: Text(isArabic ? 'العودة للرئيسية' : 'Return Home'),
                            ),
                            theme: theme,
                          ),

                        if (state.isAlreadyHasStore)
                          _buildErrorCard(
                            key: const ValueKey('already_registered_banner'),
                            title: isArabic ? 'متجر مسجل بالفعل' : 'Store Already Registered',
                            message: isArabic
                                ? 'لديك متجر مسجل بالفعل. يمكن لمالك المتجر تسجيل متجر واحد فقط.'
                                : 'You already have a registered store. A store owner can only register one store profile.',
                            actionButton: ElevatedButton(
                              key: const ValueKey('dashboard_redirect_button'),
                              onPressed: () {
                                try {
                                  context.go('/store/dashboard');
                                } catch (_) {
                                  context.go('/store-info');
                                }
                              },
                              child: Text(isArabic ? 'لوحة المتجر' : 'Go to Store Dashboard'),
                            ),
                            theme: theme,
                          ),

                        if (state.isDuplicateName)
                          _buildInlineAlert(
                            key: const ValueKey('duplicate_name_error_message'),
                            title: isArabic ? 'اسم مكرر' : 'Duplicate Name',
                            message: isArabic
                                ? (widget.isRestaurant
                                    ? 'يوجد مطعم مسجل بهذا الاسم بالفعل. يُرجى اختيار اسم آخر.'
                                    : 'يوجد متجر مسجل بهذا الاسم بالفعل. يُرجى اختيار اسم آخر.')
                                : (widget.isRestaurant
                                    ? 'A restaurant with the same name already exists. Please choose another name.'
                                    : 'A store with this name already exists. Please choose a different name.'),
                            isError: true,
                          ),

                        if (state.isNameError)
                          _buildInlineAlert(
                            key: const ValueKey('name_error_message'),
                            message: isArabic
                                ? (widget.isRestaurant
                                    ? 'اسم المطعم (بالعربية أو الإنجليزية) مطلوب.'
                                    : 'اسم المتجر (بالعربية أو الإنجليزية) مطلوب لإتمام التسجيل.')
                                : (widget.isRestaurant
                                    ? 'Restaurant name (or Arabic/English name) is required.'
                                    : 'Store name (Arabic or English) is required to proceed.'),
                            isError: true,
                          ),

                        // Section 1: Basic Information
                        _buildSectionHeader(
                          title: isArabic ? 'البيانات الأساسية' : 'Basic Information',
                          subtitle: isArabic
                              ? 'أدخل بيانات المتجر الأساسية والعلامة التجارية ونوع النشاط'
                              : 'Enter store identity, branding and business category',
                          icon: Icons.storefront,
                          theme: theme,
                        ),
                        const SizedBox(height: 16),
                        BkCard(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  key: const ValueKey('name_ar_field'),
                                  controller: _nameArController,
                                  decoration: InputDecoration(
                                    labelText: isArabic
                                        ? (widget.isRestaurant
                                            ? 'اسم المطعم (بالعربية) *'
                                            : 'اسم المتجر (بالعربية) *')
                                        : (widget.isRestaurant
                                            ? 'Restaurant Name (Arabic) *'
                                            : 'Store Name (Arabic) *'),
                                    hintText: isArabic
                                        ? 'مثال: متجر التقنية الذكية للإلكترونيات'
                                        : 'e.g. Apex Electronics & Smart Tech',
                                    prefixIcon: const Icon(Icons.store),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  key: const ValueKey('name_en_field'),
                                  controller: _nameEnController,
                                  decoration: InputDecoration(
                                    labelText: isArabic
                                        ? (widget.isRestaurant
                                            ? 'اسم المطعم (بالإنجليزية) *'
                                            : 'اسم المتجر (بالإنجليزية) *')
                                        : (widget.isRestaurant
                                            ? 'Restaurant Name (English) *'
                                            : 'Store Name (English) *'),
                                    hintText: 'e.g. Apex Electronics & Tech Store',
                                    prefixIcon: const Icon(Icons.store_mall_directory_outlined),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _businessTypeController,
                                  decoration: InputDecoration(
                                    labelText: isArabic
                                        ? 'نوع النشاط / التخصص'
                                        : 'Business Category / Type',
                                    hintText: isArabic
                                        ? 'مثال: إلكترونيات وأجهزة ذكية، هواتف، حواسيب'
                                        : 'e.g. Consumer Electronics & Smartphones',
                                    prefixIcon: const Icon(Icons.category_outlined),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _sloganController,
                                  decoration: InputDecoration(
                                    labelText: isArabic
                                        ? 'شعار المتجر اللفظي (Slogan)'
                                        : 'Store Slogan',
                                    prefixIcon: const Icon(Icons.format_quote_outlined),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _subtitleController,
                                  decoration: InputDecoration(
                                    labelText: isArabic
                                        ? 'العنوان الفرعي للمتجر'
                                        : 'Store Subtitle',
                                    prefixIcon: const Icon(Icons.subtitles_outlined),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _descriptionController,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    labelText: isArabic
                                        ? 'نبذة عن المتجر (Description)'
                                        : 'About Store (Description)',
                                    hintText: isArabic
                                        ? 'متجر متخصص في بيع وصيانة الأجهزة الذكية والإلكترونيات وملحقاتها...'
                                        : 'Retail store specialized in electronics, computing, smart devices...',
                                    prefixIcon: const Icon(Icons.description_outlined),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                DropdownButtonFormField<String>(
                                  key: const ValueKey('currency_code_dropdown'),
                                  initialValue: _selectedCurrencyCode,
                                  decoration: InputDecoration(
                                    labelText: isArabic
                                        ? 'عملة المتجر الأساسية (Currency) *'
                                        : 'Primary Currency Code *',
                                    prefixIcon: const Icon(Icons.currency_exchange),
                                    helperText: isArabic
                                        ? 'العملة الافتراضية: JOD (دينار أردني)'
                                        : 'Default: JOD (Jordanian Dinar)',
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'JOD', child: Text('دينار أردني (JOD)')),
                                    DropdownMenuItem(value: 'SAR', child: Text('ريال سعودي (SAR)')),
                                    DropdownMenuItem(value: 'AED', child: Text('درهم إماراتي (AED)')),
                                    DropdownMenuItem(value: 'USD', child: Text('دولار أمريكي (USD)')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedCurrencyCode = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Section 2: Contact & Web
                        _buildSectionHeader(
                          title: isArabic
                              ? 'بيانات الاتصال والتواجد الإلكتروني'
                              : 'Contact & Online Presence',
                          subtitle: isArabic
                              ? 'أرقام التواصل والموقع الإلكتروني وقنوات خدمة العملاء'
                              : 'Phone numbers, website, and customer support channels',
                          icon: Icons.contact_phone_outlined,
                          theme: theme,
                        ),
                        const SizedBox(height: 16),
                        BkCard(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _phoneController,
                                  decoration: InputDecoration(
                                    labelText: isArabic
                                        ? 'رقم الهاتف الأساسي / المبيعات'
                                        : 'Primary Phone / Sales',
                                    prefixIcon: const Icon(Icons.phone),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  key: const ValueKey('email_field'),
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: isArabic
                                        ? 'البريد الإلكتروني الرسمي للمتجر'
                                        : 'Official Store Email',
                                    hintText: 'e.g. contact@mynewstore.com',
                                    prefixIcon: const Icon(Icons.email_outlined),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _websiteController,
                                  decoration: InputDecoration(
                                    labelText: isArabic
                                        ? 'الموقع الإلكتروني أو المتجر الرقمي'
                                        : 'Website / E-Commerce Store',
                                    prefixIcon: const Icon(Icons.language),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        isArabic
                                            ? (widget.isRestaurant
                                                ? 'أرقام التواصل الإضافية'
                                                : 'أرقام تواصل إضافية (مبيعات / واتساب / صيانة)')
                                            : 'Additional Phone Numbers',
                                        style:
                                            theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      key: const ValueKey(
                                          'add_phone_number_button'),
                                      icon: const Icon(Icons.add, size: 16),
                                      label: Text(
                                          isArabic ? 'إضافة رقم' : 'Add Phone'),
                                      onPressed: _addPhoneNumberField,
                                    ),
                                  ],
                                ),
                                for (int i = 0;
                                    i < _dynamicPhoneNumbers.length;
                                    i++)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 6.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: TextFormField(
                                            key: ValueKey(
                                                'phone_number_field_$i'),
                                            initialValue:
                                                _dynamicPhoneNumbers[i].number,
                                            decoration: InputDecoration(
                                              labelText: isArabic
                                                  ? 'رقم الهاتف #${i + 1}'
                                                  : 'Phone #${i + 1}',
                                            ),
                                            onChanged: (val) =>
                                                _updatePhoneNumber(i, val),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          flex: 1,
                                          child: DropdownButtonFormField<String>(
                                            key: ValueKey(
                                                'phone_type_dropdown_$i'),
                                            initialValue:
                                                _dynamicPhoneNumbers[i].type,
                                            items: _phoneTypes
                                                .map((t) => DropdownMenuItem(
                                                      value: t,
                                                      child: Text(t),
                                                    ))
                                                .toList(),
                                            onChanged: (val) {
                                              if (val != null) {
                                                _updatePhoneType(i, val);
                                              }
                                            },
                                          ),
                                        ),
                                        IconButton(
                                          key: ValueKey(
                                              'remove_phone_button_$i'),
                                          icon: const Icon(Icons.delete_outline,
                                              color: Colors.redAccent),
                                          onPressed: () =>
                                              _removePhoneNumberField(i),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Section 3: Address & Location
                        _buildSectionHeader(
                          title: isArabic
                              ? 'بيانات الموقع والعنوان'
                              : 'Location & Address',
                          subtitle: isArabic
                              ? 'عنوان المتجر وموقع الخريطة والفرع الرئيسي'
                              : 'Store branch address, street and GPS coordinates',
                          icon: Icons.location_on_outlined,
                          theme: theme,
                        ),
                        const SizedBox(height: 16),
                        BkCard(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _addressController,
                                  decoration: InputDecoration(
                                    labelText: isArabic
                                        ? 'العنوان التفصيلي'
                                        : 'Detailed Address',
                                    prefixIcon: const Icon(Icons.place_outlined),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _googleMapsUrlController,
                                  decoration: InputDecoration(
                                    labelText: isArabic
                                        ? 'رابط خرائط جوجل'
                                        : 'Google Maps Link',
                                    prefixIcon: const Icon(Icons.map_outlined),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _latitudeController,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                                decimal: true),
                                        decoration: InputDecoration(
                                          labelText: isArabic
                                              ? 'خط العرض (Latitude)'
                                              : 'Latitude',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _longitudeController,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                                decimal: true),
                                        decoration: InputDecoration(
                                          labelText: isArabic
                                              ? 'خط الطول (Longitude)'
                                              : 'Longitude',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Submit Button
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            key: const ValueKey('create_restaurant_submit_button'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: state.isSubmitting
                                ? null
                                : () => _submitForm(isArabic),
                            child: state.isSubmitting
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    isArabic
                                        ? 'إنشاء المتجر وحفظ البيانات'
                                        : 'Create Store & Save',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard({
    required Key key,
    required String title,
    required String message,
    required Widget actionButton,
    required ThemeData theme,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(fontSize: 12.5, color: Colors.red.shade800),
                ),
                const SizedBox(height: 10),
                actionButton,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineAlert({
    required Key key,
    String? title,
    required String message,
    required bool isError,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? Colors.red.shade50 : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isError ? Colors.red.shade300 : Colors.amber.shade300,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.cancel_outlined : Icons.warning_amber_rounded,
            color: isError ? Colors.red.shade700 : Colors.amber.shade800,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null && title.isNotEmpty) ...[
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isError ? Colors.red.shade900 : Colors.amber.shade900,
                    ),
                  ),
                  const SizedBox(height: 3),
                ],
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isError ? Colors.red.shade900 : Colors.amber.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Backward compatibility alias class
class CreateRestaurantPage extends CreateStorePage {
  const CreateRestaurantPage({
    super.key,
    super.apiService,
    super.returnRoute,
    super.isRestaurant = true,
  });
}
