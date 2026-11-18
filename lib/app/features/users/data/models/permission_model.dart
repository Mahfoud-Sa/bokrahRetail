/// Model representing a granular system permission.
class PermissionModel {
  final int id;
  final String code;
  final String description;
  final String? category;

  const PermissionModel({
    required this.id,
    required this.code,
    required this.description,
    this.category,
  });

  /// Resolves the Arabic category label based on permission code/description.
  String get categoryDisplay {
    if (category != null && category!.isNotEmpty) return category!;
    final lower = (code + ' ' + description).toLowerCase();

    if (lower.contains('sale') ||
        lower.contains('invoice') ||
        lower.contains('pos') ||
        lower.contains('فاتورة') ||
        lower.contains('بيع') ||
        lower.contains('طلب')) {
      return 'المبيعات والفواتير';
    }
    if (lower.contains('item') ||
        lower.contains('product') ||
        lower.contains('categor') ||
        lower.contains('unit') ||
        lower.contains('barcode') ||
        lower.contains('منتج') ||
        lower.contains('صنف') ||
        lower.contains('مخزون')) {
      return 'المنتجات والمخزون';
    }
    if (lower.contains('warehouse') ||
        lower.contains('stock') ||
        lower.contains('مستودع')) {
      return 'المستودعات';
    }
    if (lower.contains('user') ||
        lower.contains('role') ||
        lower.contains('permission') ||
        lower.contains('مستخدم') ||
        lower.contains('صلاحي') ||
        lower.contains('دور')) {
      return 'المستخدمين والأدوار';
    }
    if (lower.contains('report') ||
        lower.contains('account') ||
        lower.contains('financial') ||
        lower.contains('تقرير') ||
        lower.contains('مالي') ||
        lower.contains('حساب')) {
      return 'التقارير والمحاسبة';
    }
    if (lower.contains('store') ||
        lower.contains('setting') ||
        lower.contains('متجر') ||
        lower.contains('إعداد')) {
      return 'إعدادات المتجر';
    }

    return 'صلاحيات عامة';
  }

  factory PermissionModel.fromMap(Map<String, dynamic> map) {
    return PermissionModel(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      code: map['code']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      category: map['category']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'description': description,
      if (category != null) 'category': category,
    };
  }

  /// Default baseline permissions list used for offline/fallback initialization.
  static List<PermissionModel> get defaultPermissions => const [
    // Sales & Invoices
    PermissionModel(
      id: 101,
      code: 'sales.create',
      description: 'إنشاء فواتير المبيعات ونقاط البيع (POS)',
      category: 'المبيعات والفواتير',
    ),
    PermissionModel(
      id: 102,
      code: 'sales.view',
      description: 'عرض واستعراض سجل الفواتير والمبيعات',
      category: 'المبيعات والفواتير',
    ),
    PermissionModel(
      id: 103,
      code: 'sales.refund',
      description: 'إجراء عمليات الإرجاع واسترداد المبالغ',
      category: 'المبيعات والفواتير',
    ),
    PermissionModel(
      id: 104,
      code: 'sales.discount',
      description: 'تطبيق خصومات مخصصة على الفواتير',
      category: 'المبيعات والفواتير',
    ),

    // Items & Inventory
    PermissionModel(
      id: 201,
      code: 'inventory.view',
      description: 'عرض المنتجات والكميات المتاحة والأسعار',
      category: 'المنتجات والمخزون',
    ),
    PermissionModel(
      id: 202,
      code: 'inventory.manage',
      description: 'إضافة وتعديل وحذف المنتجات والتصنيفات والوحدات',
      category: 'المنتجات والمخزون',
    ),
    PermissionModel(
      id: 203,
      code: 'inventory.adjust',
      description: 'تسوية الجرد وتعديل أرصدة المخزون يدوياً',
      category: 'المنتجات والمخزون',
    ),

    // Warehouses
    PermissionModel(
      id: 301,
      code: 'warehouses.manage',
      description: 'إدارة المستودعات ونقل البضائع بين الفروع',
      category: 'المستودعات',
    ),

    // Users & Roles
    PermissionModel(
      id: 401,
      code: 'users.manage',
      description: 'إضافة وتعديل وحذف مستخدمي النظام',
      category: 'المستخدمين والأدوار',
    ),
    PermissionModel(
      id: 402,
      code: 'roles.manage',
      description: 'إنشاء وتعديل الأدوار والصلاحيات للمشغلين',
      category: 'المستخدمين والأدوار',
    ),

    // Reports & Accounting
    PermissionModel(
      id: 501,
      code: 'reports.view',
      description: 'الاطلاع على التقارير المالية والإحصائيات والأرباح',
      category: 'التقارير والمحاسبة',
    ),
    PermissionModel(
      id: 502,
      code: 'reports.export',
      description: 'تصدير التقارير والدفاتر المحاسبية (Excel/PDF)',
      category: 'التقارير والمحاسبة',
    ),

    // Store Settings
    PermissionModel(
      id: 601,
      code: 'store.settings',
      description: 'تعديل بيانات المنشأة والسجل التجاري والإعدادات الضريبية',
      category: 'إعدادات المتجر',
    ),
  ];
}
