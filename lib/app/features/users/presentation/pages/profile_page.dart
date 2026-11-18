import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bokrah_design_system/bokrah_design_system.dart';
import '../../../../config/app_config.dart';
import '../../../../initialzation_dependencies.dart';
import '../../../auth/data/datasources/auth_token_storage.dart';
import '../../data/entities/user_entity.dart';
import '../../data/models/user_profile_dto.dart';
import '../../data/services/profile_service.dart';
import '../../data/services/users_service.dart';
import '../../data/services/working_days_service.dart';
import '../utils/profile_file_picker.dart';
import '../widgets/working_days_section.dart';

class _PhoneEntry {
  final TextEditingController controller;
  String type;

  _PhoneEntry({required String number, required this.type})
      : controller = TextEditingController(text: number);

  void dispose() {
    controller.dispose();
  }
}

class ProfilePage extends StatefulWidget {
  final ProfileService? profileService;

  const ProfilePage({super.key, this.profileService});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileService _profileService;
  late final WorkingDaysService _workingDaysService;
  final UsersService _usersService = UsersService();
  int _userId = 0;

  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _birthDateController;
  DateTime? _selectedBirthDate;

  late TextEditingController _newPasswordController;
  late TextEditingController _confirmedPasswordController;
  bool _obscureNewPassword = true;
  bool _obscureConfirmedPassword = true;
  bool _isChangingPassword = false;

  final List<_PhoneEntry> _phoneEntries = [];

  String? _profilePicture;
  Uint8List? _localImageBytes;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  String? _errorMessage;

  static const Map<String, String> _phoneTypeLabels = {
    'Mobile': 'جوال',
    'Work': 'عمل',
    'WhatsApp': 'واتساب',
    'Home': 'منزل',
  };

  @override
  void initState() {
    super.initState();
    _profileService = widget.profileService ??
        (singelton.isRegistered<ProfileService>()
            ? singelton<ProfileService>()
            : ApiProfileService(tokenStorage: singelton<AuthTokenStorage>()));

    _workingDaysService = singelton.isRegistered<WorkingDaysService>()
        ? singelton<WorkingDaysService>()
        : ApiWorkingDaysService(tokenStorage: singelton<AuthTokenStorage>());

    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _birthDateController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmedPasswordController = TextEditingController();

    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    _newPasswordController.dispose();
    _confirmedPasswordController.dispose();
    for (final entry in _phoneEntries) {
      entry.dispose();
    }
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (singelton.isRegistered<AuthTokenStorage>()) {
        final session = await singelton<AuthTokenStorage>().getSession();
        if (session != null && session.userId.isNotEmpty) {
          _userId = int.tryParse(session.userId) ?? 0;
        }
      }
    } catch (_) {}

    try {
      final profile = await _profileService.getProfile();
      if (profile.id != null && profile.id! > 0) {
        _userId = profile.id!;
      }
      _populateForm(profile);
    } catch (e) {
      debugPrint('Failed to load profile from API: $e');
      _errorMessage = e is ProfileApiException ? e.message : 'تعذر تحميل بيانات الملف الشخصي من الخادم';

      // Fallback to local cached user data if available
      try {
        final localUsers = await _usersService.getAllUsers();
        if (localUsers.isNotEmpty) {
          final first = localUsers.first;
          if (_userId == 0 && first.id != null) {
            _userId = first.id!;
          }
          _nameController.text = first.name;
          _emailController.text = first.email;
          if (first.birthDate != null && first.birthDate!.isNotEmpty) {
            _birthDateController.text = first.birthDate!;
            _selectedBirthDate = DateTime.tryParse(first.birthDate!);
          }
          if (_phoneEntries.isEmpty && first.phoneNumber != null && first.phoneNumber!.isNotEmpty) {
            _phoneEntries.add(_PhoneEntry(number: first.phoneNumber!, type: 'Mobile'));
          }
          _profilePicture = first.profileImage;
        }
      } catch (_) {}

      if (_phoneEntries.isEmpty) {
        _phoneEntries.add(_PhoneEntry(number: '', type: 'Mobile'));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _populateForm(UserProfileDto profile) {
    _nameController.text = profile.fullName;
    _emailController.text = profile.email;
    _selectedBirthDate = profile.birthDate;
    _birthDateController.text = _formatDate(profile.birthDate);
    _profilePicture = profile.profilePicture;

    for (final entry in _phoneEntries) {
      entry.dispose();
    }
    _phoneEntries.clear();

    if (profile.phoneNumbers.isNotEmpty) {
      for (final p in profile.phoneNumbers) {
        _phoneEntries.add(_PhoneEntry(number: p.number, type: p.type));
      }
    } else {
      _phoneEntries.add(_PhoneEntry(number: '', type: 'Mobile'));
    }
  }

  void _addPhoneField() {
    setState(() {
      _phoneEntries.add(_PhoneEntry(number: '', type: 'Mobile'));
    });
  }

  void _removePhoneField(int index) {
    if (_phoneEntries.length <= 1) return;
    setState(() {
      final entry = _phoneEntries.removeAt(index);
      entry.dispose();
    });
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();
    final initialDate = _selectedBirthDate ?? DateTime(now.year - 25, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now) ? now : initialDate,
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'اختر تاريخ الميلاد',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
    );

    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final phoneDtos = _phoneEntries
        .map((e) => ProfilePhoneNumberDto(
              number: e.controller.text.trim(),
              type: e.type,
            ))
        .where((p) => p.number.isNotEmpty)
        .toList();

    final profileDto = UserProfileDto(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      birthDate: _selectedBirthDate,
      phoneNumbers: phoneDtos,
      profilePicture: _profilePicture,
    );

    try {
      final updated = await _profileService.updateProfile(profileDto);
      _populateForm(updated);

      // Synchronize with local storage cache so other parts of the app stay fresh
      final primaryPhone = phoneDtos.isNotEmpty ? phoneDtos.first.number : null;
      await _usersService.saveUser(
        UserEntity(
          name: updated.fullName,
          email: updated.email,
          phoneNumber: primaryPhone,
          birthDate: _formatDate(updated.birthDate),
          profileImage: updated.profilePicture ?? _profilePicture,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('تم حفظ وتحديث بيانات الملف الشخصي بنجاح'),
              ],
            ),
            backgroundColor: Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      final errorMsg = e is ProfileApiException ? e.message : 'حدث خطأ أثناء حفظ الملف الشخصي: $e';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMsg)),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _isChangingPassword = true);

    try {
      await _profileService.changePassword(
        newPassword: _newPasswordController.text,
        confirmedPassword: _confirmedPasswordController.text,
      );

      _newPasswordController.clear();
      _confirmedPasswordController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('تم تغيير كلمة المرور بنجاح'),
              ],
            ),
            backgroundColor: Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      final errorMsg = e is ProfileApiException ? e.message : 'فشل تغيير كلمة المرور: $e';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMsg)),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChangingPassword = false);
      }
    }
  }

  Future<void> _handleUploadImage(List<int> bytes, String fileName) async {
    setState(() => _isUploadingImage = true);

    try {
      final newUrl = await _profileService.uploadProfileImage(
        fileBytes: bytes,
        fileName: fileName,
      );

      setState(() {
        _localImageBytes = Uint8List.fromList(bytes);
        if (newUrl != null && newUrl.isNotEmpty) {
          _profilePicture = newUrl;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('تم رفع وتحديث صورة الملف الشخصي بنجاح'),
              ],
            ),
            backgroundColor: Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      final errorMsg = e is ProfileApiException ? e.message : 'فشل رفع الصورة: $e';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMsg)),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'تغيير الصورة الشخصية',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.folder_open, color: Color(0xFF0284C7)),
                    title: const Text('اختيار صورة من الجهاز'),
                    subtitle: const Text('استعراض ملف صورة (PNG, JPG, WebP)'),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final picked = await ProfileFilePicker.pickImageFile();
                      if (picked != null) {
                        await _handleUploadImage(picked.bytes, picked.fileName);
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.edit_note, color: Color(0xFF16A34A)),
                    title: const Text('إدخال مسار ملف محلي'),
                    subtitle: const Text('كتابة مسار الصورة على جهازك'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showPathInputDialog();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPathInputDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إدخال مسار ملف الصورة'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'أدخل المسار الكامل لملف الصورة على جهازك:',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: r'C:\Users\...\avatar.png',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final path = controller.text.trim();
                  Navigator.pop(ctx);
                  if (path.isNotEmpty) {
                    final picked = await ProfileFilePicker.loadFromPath(path);
                    if (picked != null) {
                      await _handleUploadImage(picked.bytes, picked.fileName);
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تعذر العثور على الملف بالمسار المحدد'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                child: const Text('رفع'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatarWidget({double size = 110}) {
    ImageProvider? imageProvider;
    if (_localImageBytes != null) {
      imageProvider = MemoryImage(_localImageBytes!);
    } else if (_profilePicture != null && _profilePicture!.isNotEmpty) {
      final pic = _profilePicture!;
      if (pic.startsWith('http://') || pic.startsWith('https://')) {
        imageProvider = NetworkImage(pic);
      } else if (pic.startsWith('/') || pic.contains(RegExp(r'^[a-zA-Z]:'))) {
        imageProvider = FileImage(File(pic));
      } else {
        final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
        imageProvider = NetworkImage('$base/$pic');
      }
    }

    final buttonSize = size * 0.32;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withAlpha(50),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: imageProvider != null
                  ? Image(
                      image: imageProvider,
                      fit: BoxFit.cover,
                      width: size,
                      height: size,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.person,
                          size: size * 0.55,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        );
                      },
                    )
                  : Icon(
                      Icons.person,
                      size: size * 0.55,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
            ),
          ),
          if (_isUploadingImage)
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withAlpha(120),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Material(
              color: Theme.of(context).colorScheme.primary,
              shape: const CircleBorder(),
              elevation: 4,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _isUploadingImage ? null : _showImagePickerOptions,
                child: Padding(
                  padding: EdgeInsets.all(buttonSize * 0.22),
                  child: Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: buttonSize * 0.55,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a responsive grid row with 2 columns on wide screens and 1 column on mobile.
  Widget _buildGridRow({
    required bool isWide,
    required Widget first,
    required Widget second,
    double gap = 16,
  }) {
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: first),
          SizedBox(width: gap),
          Expanded(child: second),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        first,
        SizedBox(height: gap),
        second,
      ],
    );
  }

  Widget _buildFieldGroup({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      suffixIcon: suffix,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
    );
  }

  Widget _buildHeaderCard(bool isWide) {
    final theme = Theme.of(context);
    final displayName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'الملف الشخصي';
    final displayEmail = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : 'لا يوجد بريد إلكتروني مسجل';

    return BkCard(
      child: Padding(
        padding: EdgeInsets.all(isWide ? 24 : 18),
        child: isWide
            ? Row(
                children: [
                  _buildAvatarWidget(size: 105),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A).withAlpha(30),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF16A34A).withAlpha(80),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, size: 14, color: Color(0xFF16A34A)),
                                  SizedBox(width: 4),
                                  Text(
                                    'نشط ومفعل',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              displayEmail,
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        if (_selectedBirthDate != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.cake_outlined,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatDate(_selectedBirthDate),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  _buildAvatarWidget(size: 96),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayEmail,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'الملف الشخصي',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث البيانات',
              onPressed: _isLoading ? null : _loadProfile,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('جاري تحميل بيانات الملف الشخصي...'),
                  ],
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 640;
                  final cardMaxWidth = isWide ? 820.0 : 480.0;
                  final horizontalPadding = isWide ? 28.0 : 16.0;

                  return Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 24,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: cardMaxWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.amber.shade300),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.amber.shade800),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: TextStyle(
                                          color: Colors.amber.shade900,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _loadProfile,
                                      child: const Text('إعادة المحاولة'),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Responsive Profile Header Overview
                            _buildHeaderCard(isWide),
                            const SizedBox(height: 20),

                            // Personal Information Card (Using Grid System)
                            BkCard(
                              child: Padding(
                                padding: EdgeInsets.all(isWide ? 24 : 18),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.person_outline,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'البيانات الأساسية',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),

                                      // Grid Row 1: Full Name & Email
                                      _buildGridRow(
                                        isWide: isWide,
                                        first: _buildFieldGroup(
                                          label: 'الاسم الكامل *',
                                          child: TextFormField(
                                            controller: _nameController,
                                            decoration: _inputDecoration(
                                              hint: 'أدخل الاسم الكامل',
                                              icon: Icons.badge_outlined,
                                            ),
                                            validator: (v) {
                                              if (v == null || v.trim().isEmpty) {
                                                return 'الاسم الكامل مطلوب';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        second: _buildFieldGroup(
                                          label: 'البريد الإلكتروني *',
                                          child: TextFormField(
                                            controller: _emailController,
                                            keyboardType: TextInputType.emailAddress,
                                            decoration: _inputDecoration(
                                              hint: 'example@domain.com',
                                              icon: Icons.email_outlined,
                                            ),
                                            validator: (v) {
                                              if (v == null || v.trim().isEmpty) {
                                                return 'البريد الإلكتروني مطلوب';
                                              }
                                              if (!v.contains('@') || !v.contains('.')) {
                                                return 'يرجى إدخال بريد إلكتروني صحيح';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      // Grid Row 2: Birth Date & Account Status
                                      _buildGridRow(
                                        isWide: isWide,
                                        first: _buildFieldGroup(
                                          label: 'تاريخ الميلاد',
                                          child: TextFormField(
                                            controller: _birthDateController,
                                            readOnly: true,
                                            onTap: _selectBirthDate,
                                            decoration: _inputDecoration(
                                              hint: 'YYYY-MM-DD',
                                              icon: Icons.cake_outlined,
                                              suffix: IconButton(
                                                icon: const Icon(Icons.calendar_month_outlined),
                                                onPressed: _selectBirthDate,
                                              ),
                                            ),
                                          ),
                                        ),
                                        second: _buildFieldGroup(
                                          label: 'نوع الحساب',
                                          child: Container(
                                            height: 48,
                                            padding: const EdgeInsets.symmetric(horizontal: 14),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.surface,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: Theme.of(context)
                                                    .dividerColor
                                                    .withAlpha(50),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.shield_outlined,
                                                  color: Theme.of(context).colorScheme.primary,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                const Text(
                                                  'مالك / مدير المتجر',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),

                                      // Save Basic Info Button
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: SizedBox(
                                          height: 46,
                                          child: ElevatedButton.icon(
                                            onPressed:
                                                (_isSaving || _isLoading) ? null : _saveProfile,
                                            icon: _isSaving
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor: AlwaysStoppedAnimation<Color>(
                                                          Colors.white),
                                                    ),
                                                  )
                                                : const Icon(Icons.check, size: 20),
                                            label: Text(
                                              _isSaving ? 'جاري الحفظ...' : 'حفظ البيانات الشخصية',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Theme.of(context).colorScheme.primary,
                                              foregroundColor:
                                                  Theme.of(context).colorScheme.onPrimary,
                                              padding: const EdgeInsets.symmetric(horizontal: 24),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Phone Numbers Card
                            BkCard(
                              child: Padding(
                                padding: EdgeInsets.all(isWide ? 24 : 18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.phone_outlined,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'أرقام الهاتف',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        TextButton.icon(
                                          onPressed: _addPhoneField,
                                          icon: const Icon(Icons.add, size: 18),
                                          label: const Text('إضافة رقم'),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 24),
                                    ..._phoneEntries.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final item = entry.value;
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Phone number input
                                            Expanded(
                                              flex: 3,
                                              child: TextFormField(
                                                controller: item.controller,
                                                keyboardType: TextInputType.phone,
                                                decoration: _inputDecoration(
                                                  hint: '05xxxxxxxx',
                                                  icon: Icons.phone,
                                                ),
                                                validator: (v) {
                                                  if (index == 0 &&
                                                      (v == null || v.trim().isEmpty)) {
                                                    return 'رقم الهاتف الأساسي مطلوب';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),

                                            // Phone type dropdown
                                            Expanded(
                                              flex: 2,
                                              child: DropdownButtonFormField<String>(
                                                value: _phoneTypeLabels.containsKey(item.type)
                                                    ? item.type
                                                    : 'Mobile',
                                                decoration: _inputDecoration(
                                                  hint: 'النوع',
                                                  icon: Icons.label_outline,
                                                ),
                                                items: _phoneTypeLabels.entries.map((e) {
                                                  return DropdownMenuItem<String>(
                                                    value: e.key,
                                                    child: Text(e.value),
                                                  );
                                                }).toList(),
                                                onChanged: (val) {
                                                  if (val != null) {
                                                    setState(() => item.type = val);
                                                  }
                                                },
                                              ),
                                            ),

                                            // Delete button (if more than 1 item)
                                            if (_phoneEntries.length > 1) ...[
                                              const SizedBox(width: 4),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline,
                                                    color: Colors.red),
                                                tooltip: 'حذف الرقم',
                                                onPressed: () => _removePhoneField(index),
                                              ),
                                            ],
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Working Days & Shift Schedule Card
                            WorkingDaysSection(
                              userId: _userId,
                              workingDaysService: _workingDaysService,
                              isWide: isWide,
                            ),
                            const SizedBox(height: 20),

                            // Change Password Card (Using Grid System)
                            BkCard(
                              child: Padding(
                                padding: EdgeInsets.all(isWide ? 24 : 18),
                                child: Form(
                                  key: _passwordFormKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.lock_outline,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'تغيير كلمة المرور',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),

                                      // Grid Row: New Password & Confirmed Password
                                      _buildGridRow(
                                        isWide: isWide,
                                        first: _buildFieldGroup(
                                          label: 'كلمة المرور الجديدة *',
                                          child: TextFormField(
                                            controller: _newPasswordController,
                                            obscureText: _obscureNewPassword,
                                            decoration: _inputDecoration(
                                              hint: 'أدخل كلمة المرور الجديدة',
                                              icon: Icons.lock_outline,
                                              suffix: IconButton(
                                                icon: Icon(
                                                  _obscureNewPassword
                                                      ? Icons.visibility_off
                                                      : Icons.visibility,
                                                ),
                                                onPressed: () {
                                                  setState(() =>
                                                      _obscureNewPassword = !_obscureNewPassword);
                                                },
                                              ),
                                            ),
                                            validator: (v) {
                                              if (v == null || v.trim().isEmpty) {
                                                return 'كلمة المرور الجديدة مطلوبة';
                                              }
                                              if (v.trim().length < 6) {
                                                return 'يجب أن لا تقل كلمة المرور عن 6 أحرف';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        second: _buildFieldGroup(
                                          label: 'تأكيد كلمة المرور الجديدة *',
                                          child: TextFormField(
                                            controller: _confirmedPasswordController,
                                            obscureText: _obscureConfirmedPassword,
                                            decoration: _inputDecoration(
                                              hint: 'أعد إدخال كلمة المرور',
                                              icon: Icons.lock_reset,
                                              suffix: IconButton(
                                                icon: Icon(
                                                  _obscureConfirmedPassword
                                                      ? Icons.visibility_off
                                                      : Icons.visibility,
                                                ),
                                                onPressed: () {
                                                  setState(() => _obscureConfirmedPassword =
                                                      !_obscureConfirmedPassword);
                                                },
                                              ),
                                            ),
                                            validator: (v) {
                                              if (v == null || v.trim().isEmpty) {
                                                return 'يرجى تأكيد كلمة المرور';
                                              }
                                              if (v != _newPasswordController.text) {
                                                return 'كلمتا المرور غير متطابقتين';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      // Action Button
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: SizedBox(
                                          height: 46,
                                          child: ElevatedButton.icon(
                                            onPressed:
                                                _isChangingPassword ? null : _changePassword,
                                            icon: _isChangingPassword
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor: AlwaysStoppedAnimation<Color>(
                                                          Colors.white),
                                                    ),
                                                  )
                                                : const Icon(Icons.key, size: 20),
                                            label: Text(
                                              _isChangingPassword
                                                  ? 'جاري التغيير...'
                                                  : 'تحديث كلمة المرور',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Theme.of(context).colorScheme.secondary,
                                              foregroundColor:
                                                  Theme.of(context).colorScheme.onSecondary,
                                              padding: const EdgeInsets.symmetric(horizontal: 24),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
