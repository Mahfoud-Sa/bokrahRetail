import 'package:bokrah_retail/app/features/users/data/entities/user_entity.dart';
import 'package:bokrah_retail/app/features/users/data/services/users_service.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UsersService _usersService = UsersService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _birthDateController;

  String? _selectedGender;
  bool _isLoading = true;
  UserEntity? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    setState(() => _isLoading = true);
    // Note: In a real app, this would get the logged-in user's ID
    // For now, we'll fetch the first user or create a mock if none exists
    final users = await _usersService.getAllUsers();
    if (users.isNotEmpty) {
      _currentUser = users.first;
    } else {
      _currentUser = UserEntity(
        name: 'عبدالله سالم بن زقر',
        email: 'abdullah@example.com',
        roles: ['Admin'],
      );
    }

    _nameController = TextEditingController(text: _currentUser?.name);
    _emailController = TextEditingController(text: _currentUser?.email);
    _phoneController = TextEditingController(text: _currentUser?.phoneNumber);
    _addressController = TextEditingController(text: _currentUser?.address);
    _birthDateController = TextEditingController(text: _currentUser?.birthDate);
    _selectedGender = _currentUser?.gender ?? 'ذكر';

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final updatedUser = UserEntity(
        id: _currentUser?.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        birthDate: _birthDateController.text.trim(),
        gender: _selectedGender,
        roles: _currentUser?.roles ?? ['Staff'],
        isActive: _currentUser?.isActive ?? true,
        createdAt: _currentUser?.createdAt,
      );

      bool success;
      if (_currentUser?.id != null) {
        success = await _usersService.updateUser(updatedUser);
      } else {
        success = await _usersService.saveUser(updatedUser);
      }

      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الملف الشخصي بنجاح')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ملفي الشخصي'),
          backgroundColor: const Color(0xFF2E7D64),
          foregroundColor: Colors.white,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Profile Image
                      Center(
                        child: Stack(
                          children: [
                            const CircleAvatar(
                              radius: 60,
                              backgroundColor: Color(0xFFE0E0E0),
                              child: Icon(
                                Icons.person,
                                size: 80,
                                color: Colors.grey,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(
                                backgroundColor: const Color(0xFF2E7D64),
                                radius: 20,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'ميزة تغيير الصورة قيد التطوير',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      _buildTextField(
                        _nameController,
                        'الاسم الكامل',
                        Icons.person,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        _emailController,
                        'البريد الإلكتروني',
                        Icons.email,
                        isEmail: true,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        _phoneController,
                        'رقم الهاتف',
                        Icons.phone,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        _addressController,
                        'العنوان',
                        Icons.location_on,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        _birthDateController,
                        'تاريخ الميلاد',
                        Icons.cake,
                        isDate: true,
                      ),
                      const SizedBox(height: 24),

                      // Gender
                      Row(
                        children: [
                          const Text(
                            'الجنس:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 24),
                          ChoiceChip(
                            label: const Text('ذكر'),
                            selected: _selectedGender == 'ذكر',
                            onSelected: (val) =>
                                setState(() => _selectedGender = 'ذكر'),
                          ),
                          const SizedBox(width: 12),
                          ChoiceChip(
                            label: const Text('أنثى'),
                            selected: _selectedGender == 'أنثى',
                            onSelected: (val) =>
                                setState(() => _selectedGender = 'أنثى'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D64),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'حفظ التغييرات',
                            style: TextStyle(
                              fontSize: 18,
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
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isEmail = false,
    bool isDate = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: isDate,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      onTap: isDate
          ? () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1950),
                lastDate: DateTime(2100),
              );
              if (pickedDate != null) {
                setState(() {
                  controller.text =
                      "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}";
                });
              }
            }
          : null,
      validator: (v) {
        if (v == null || v.isEmpty) return 'هذا الحقل مطلوب';
        if (isEmail && !v.contains('@')) return 'بريد غير صحيح';
        return null;
      },
    );
  }
}
