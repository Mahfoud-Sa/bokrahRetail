import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bokrah_design_system/bokrah_design_system.dart';
import 'package:bokrah_retail/app/config/theme.dart';

/// Pre-configured feature types supported by [ComingSoonView] and [ComingSoonPage].
enum ComingSoonFeature {
  general,
  barcodes,
  invoices,
  items,
  units,
  warehouses,
  categories,
  financialReports,
  chartOfAccounts,
  journalEntries,
  transactions,
  dashboard,
}

/// A reusable Coming Soon view designed for desktop, tablet, and mobile.
/// Can be embedded into existing tabs/views or rendered inside [ComingSoonPage].
class ComingSoonView extends StatelessWidget {
  final ComingSoonFeature feature;
  final String? title;
  final String? subtitle;
  final String? badgeText;
  final String? estimatedRelease;
  final IconData? icon;
  final List<String>? previewPoints;
  final VoidCallback? onBack;
  final bool showBackButton;
  final Widget? customAction;

  const ComingSoonView({
    super.key,
    this.feature = ComingSoonFeature.general,
    this.title,
    this.subtitle,
    this.badgeText,
    this.estimatedRelease,
    this.icon,
    this.previewPoints,
    this.onBack,
    this.showBackButton = true,
    this.customAction,
  });

  const ComingSoonView.barcodes({
    super.key,
    this.title,
    this.subtitle,
    this.badgeText,
    this.estimatedRelease,
    this.icon,
    this.previewPoints,
    this.onBack,
    this.showBackButton = true,
    this.customAction,
  }) : feature = ComingSoonFeature.barcodes;

  const ComingSoonView.invoices({
    super.key,
    this.title,
    this.subtitle,
    this.badgeText,
    this.estimatedRelease,
    this.icon,
    this.previewPoints,
    this.onBack,
    this.showBackButton = true,
    this.customAction,
  }) : feature = ComingSoonFeature.invoices;

  const ComingSoonView.items({
    super.key,
    this.title,
    this.subtitle,
    this.badgeText,
    this.estimatedRelease,
    this.icon,
    this.previewPoints,
    this.onBack,
    this.showBackButton = true,
    this.customAction,
  }) : feature = ComingSoonFeature.items;

  const ComingSoonView.units({
    super.key,
    this.title,
    this.subtitle,
    this.badgeText,
    this.estimatedRelease,
    this.icon,
    this.previewPoints,
    this.onBack,
    this.showBackButton = true,
    this.customAction,
  }) : feature = ComingSoonFeature.units;

  const ComingSoonView.warehouses({
    super.key,
    this.title,
    this.subtitle,
    this.badgeText,
    this.estimatedRelease,
    this.icon,
    this.previewPoints,
    this.onBack,
    this.showBackButton = true,
    this.customAction,
  }) : feature = ComingSoonFeature.warehouses;

  const ComingSoonView.categories({
    super.key,
    this.title,
    this.subtitle,
    this.badgeText,
    this.estimatedRelease,
    this.icon,
    this.previewPoints,
    this.onBack,
    this.showBackButton = true,
    this.customAction,
  }) : feature = ComingSoonFeature.categories;

  const ComingSoonView.financialReports({
    super.key,
    this.title,
    this.subtitle,
    this.badgeText,
    this.estimatedRelease,
    this.icon,
    this.previewPoints,
    this.onBack,
    this.showBackButton = true,
    this.customAction,
  }) : feature = ComingSoonFeature.financialReports;

  const ComingSoonView.chartOfAccounts({
    super.key,
    this.title,
    this.subtitle,
    this.badgeText,
    this.estimatedRelease,
    this.icon,
    this.previewPoints,
    this.onBack,
    this.showBackButton = true,
    this.customAction,
  }) : feature = ComingSoonFeature.chartOfAccounts;

  const ComingSoonView.journalEntries({
    super.key,
    this.title,
    this.subtitle,
    this.badgeText,
    this.estimatedRelease,
    this.icon,
    this.previewPoints,
    this.onBack,
    this.showBackButton = true,
    this.customAction,
  }) : feature = ComingSoonFeature.journalEntries;

  const ComingSoonView.transactions({
    super.key,
    this.title,
    this.subtitle,
    this.badgeText,
    this.estimatedRelease,
    this.icon,
    this.previewPoints,
    this.onBack,
    this.showBackButton = true,
    this.customAction,
  }) : feature = ComingSoonFeature.transactions;

  const ComingSoonView.dashboard({
    super.key,
    this.title,
    this.subtitle,
    this.badgeText,
    this.estimatedRelease,
    this.icon,
    this.previewPoints,
    this.onBack,
    this.showBackButton = true,
    this.customAction,
  }) : feature = ComingSoonFeature.dashboard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = theme.brightness == Brightness.dark;

    final resolvedTitle = title ?? _resolveDefaultTitle(isArabic);
    final resolvedSubtitle = subtitle ?? _resolveDefaultSubtitle(isArabic);
    final resolvedBadge = badgeText ?? _resolveDefaultBadge(isArabic);
    final resolvedIcon = icon ?? _resolveDefaultIcon();
    final resolvedEstimated = estimatedRelease ?? _resolveDefaultEstimated(isArabic);
    final resolvedPreviewPoints = previewPoints ?? _resolveDefaultPreviewPoints(isArabic);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: BkSpace.lg,
        vertical: BkSpace.xl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            padding: const EdgeInsets.all(BkSpace.xl),
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(BkRadius.xl),
              border: Border.all(
                color: isDark
                    ? AppTheme.darkBorder
                    : theme.colorScheme.primary.withValues(alpha: 0.14),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.25)
                      : theme.colorScheme.primary.withValues(alpha: 0.05),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Status Badge
                _buildStatusBadge(theme, resolvedBadge, isDark),
                const SizedBox(height: BkSpace.lg),

                // Glowing Icon Container
                _buildIconContainer(theme, resolvedIcon, isDark),
                const SizedBox(height: BkSpace.lg),

                // Title
                Text(
                  resolvedTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: BkSpace.sm),

                // Subtitle / Description
                Text(
                  resolvedSubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                    height: 1.6,
                  ),
                ),

                // Estimated Release Tag
                if (resolvedEstimated != null) ...[
                  const SizedBox(height: BkSpace.md),
                  _buildEstimatedReleaseBadge(theme, resolvedEstimated, isArabic, isDark),
                ],

                // Upcoming highlights / preview points
                if (resolvedPreviewPoints != null && resolvedPreviewPoints.isNotEmpty) ...[
                  const SizedBox(height: BkSpace.xl),
                  _buildPreviewPointsSection(theme, resolvedPreviewPoints, isArabic, isDark),
                ],

                const SizedBox(height: BkSpace.xl),

                // Action Buttons
                _buildActions(context, theme, isArabic),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _resolveDefaultTitle(bool isArabic) {
    switch (feature) {
      case ComingSoonFeature.barcodes:
        return isArabic ? 'إدارة الباركود والماسح الضوئي' : 'Barcode & Scanner Management';
      case ComingSoonFeature.invoices:
        return isArabic ? 'إدارة الفواتير ونقاط البيع' : 'Invoices & POS Management';
      case ComingSoonFeature.items:
        return isArabic ? 'كتالوج الأصناف والمنتجات' : 'Items & Products Catalog';
      case ComingSoonFeature.units:
        return isArabic ? 'وحدات القياس والتحويلات' : 'Units & Packaging Conversions';
      case ComingSoonFeature.warehouses:
        return isArabic ? 'إدارة المستودعات وحركات المخزون' : 'Warehouses & Inventory Movement';
      case ComingSoonFeature.categories:
        return isArabic ? 'فئات المنتجات والتصنيفات' : 'Product Categories & Hierarchy';
      case ComingSoonFeature.financialReports:
        return isArabic ? 'التقارير المالية والقوائم الختامية' : 'Financial Reports & Statements';
      case ComingSoonFeature.chartOfAccounts:
        return isArabic ? 'دليل الحسابات والشجرة المحاسبية' : 'Chart of Accounts';
      case ComingSoonFeature.journalEntries:
        return isArabic ? 'دفتر اليومية العامة والقيود' : 'General Journal & Entries';
      case ComingSoonFeature.transactions:
        return isArabic ? 'المبيعات والمعاملات المالية' : 'Sales & Transactions';
      case ComingSoonFeature.dashboard:
        return isArabic ? 'لوحة التحكم والمؤشرات' : 'Accounting Dashboard';
      case ComingSoonFeature.general:
        return isArabic ? 'قريباً' : 'Coming Soon';
    }
  }

  String _resolveDefaultSubtitle(bool isArabic) {
    switch (feature) {
      case ComingSoonFeature.barcodes:
        return isArabic
            ? 'نظام متقدم لتوليد وطباعة ملصقات الباركود والربط المباشر مع أجهزة المسح الضوئي وكاميرات الأجهزة الذكية.'
            : 'Advanced barcode generation, custom label printing, and seamless integration with hardware scanners and smart cameras.';
      case ComingSoonFeature.invoices:
        return isArabic
            ? 'نظام فوترة إلكترونية متكامل يدعم الفواتير الضريبية المبسطة، مرتجعات المبيعات، والطباعة الحرارية السريعة.'
            : 'Integrated electronic invoicing system supporting simplified tax invoices, sales returns, and rapid thermal receipt printing.';
      case ComingSoonFeature.items:
        return isArabic
            ? 'كتالوج شامل لإدارة أصناف التجزئة، مصفوفات التسعير، مستويات إعادة الطلب، وتتبع تواريخ الصلاحية.'
            : 'Comprehensive retail item catalog with dynamic pricing matrices, reorder levels, and expiry tracking.';
      case ComingSoonFeature.units:
        return isArabic
            ? 'تعريف وحدات القياس المتعددة (قطعة، حبة، كرتون، كجم) مع حساب دقيق لمعاملات التحويل التلقائي بين الوحدات.'
            : 'Define multi-level units (Piece, Pack, Box, Kg) with automated conversion factors for inventory and sales.';
      case ComingSoonFeature.warehouses:
        return isArabic
            ? 'نظام متكامل لإدارة المستودعات المتعددة، تتبع مواقع الأرفف، والتحويل المخزني الفوري بين الفروع.'
            : 'Full multi-warehouse management with shelf/bin locations, stock transfers, and reconciliation audits.';
      case ComingSoonFeature.categories:
        return isArabic
            ? 'هيكلة وتصنيف شجري للمنتجات مع إمكانية ربط الفئات بنقاط البيع وإعدادات الضرائب والخصومات.'
            : 'Hierarchical category structure with POS channel mapping and customized tax configurations.';
      case ComingSoonFeature.financialReports:
        return isArabic
            ? 'قوائم الدخل، الميزانية العمومية، ميزان المراجعة، وتقارير الإقرارات الضريبية اللحظية المتوافقة.'
            : 'Income statements, balance sheets, trial balances, and real-time VAT declaration reports.';
      case ComingSoonFeature.chartOfAccounts:
        return isArabic
            ? 'دليل محاسبي مرن ومتوافق مع المعايير الدولية (الأصول، الخصوم، حقوق الملكية، الإيرادات، المصروفات).'
            : 'Flexible and standardized chart of accounts covering assets, liabilities, equity, revenue, and expenses.';
      case ComingSoonFeature.journalEntries:
        return isArabic
            ? 'تسجيل القيود المحاسبية المزدوجة (مدين/دائن) ومراجعة الحركات المالية مع الترحيل الآلي للأستاذ العام.'
            : 'Double-entry bookkeeping (debit/credit) with ledger review and automatic balanced posting.';
      case ComingSoonFeature.transactions:
        return isArabic
            ? 'سجل العمليات المالية اللحظية، مراقبة الكاش والمبيعات النقدية والإلكترونية، وإغلاق الورديات.'
            : 'Real-time financial activity stream, cash register monitoring, electronic payments, and shift closings.';
      case ComingSoonFeature.dashboard:
        return isArabic
            ? 'نظرة شاملة ومؤشرات أداء رئيسية (KPIs) للإيرادات، المصروفات، صافي الأرباح، وحركة المبيعات اللحظية.'
            : 'Comprehensive executive dashboard with real-time KPIs for revenue, expenses, net margin, and sales velocity.';
      case ComingSoonFeature.general:
        return isArabic
            ? 'نحن نعمل جاهدين على تطوير هذه الميزة لتقديم أفضل تجربة إدارة لمشروعك. ترقبوا إطلاقها في التحديث القادم!'
            : 'We are actively working on this feature to bring you the best management experience. Stay tuned for the upcoming update!';
    }
  }

  String _resolveDefaultBadge(bool isArabic) {
    switch (feature) {
      case ComingSoonFeature.general:
        return isArabic ? 'قيد التطوير' : 'In Development';
      default:
        return isArabic ? 'تحديث v3.5.0' : 'Update v3.5.0';
    }
  }

  IconData _resolveDefaultIcon() {
    switch (feature) {
      case ComingSoonFeature.barcodes:
        return Icons.qr_code_scanner_rounded;
      case ComingSoonFeature.invoices:
        return Icons.receipt_long_rounded;
      case ComingSoonFeature.items:
        return Icons.inventory_2_rounded;
      case ComingSoonFeature.units:
        return Icons.straighten_rounded;
      case ComingSoonFeature.warehouses:
        return Icons.warehouse_rounded;
      case ComingSoonFeature.categories:
        return Icons.category_rounded;
      case ComingSoonFeature.financialReports:
        return Icons.analytics_rounded;
      case ComingSoonFeature.chartOfAccounts:
        return Icons.account_tree_rounded;
      case ComingSoonFeature.journalEntries:
        return Icons.menu_book_rounded;
      case ComingSoonFeature.transactions:
        return Icons.point_of_sale_rounded;
      case ComingSoonFeature.dashboard:
        return Icons.dashboard_rounded;
      case ComingSoonFeature.general:
        return Icons.rocket_launch_rounded;
    }
  }

  String? _resolveDefaultEstimated(bool isArabic) {
    switch (feature) {
      case ComingSoonFeature.general:
        return null;
      default:
        return isArabic ? 'الربع الأول 2027' : 'Q1 2027';
    }
  }

  List<String>? _resolveDefaultPreviewPoints(bool isArabic) {
    switch (feature) {
      case ComingSoonFeature.barcodes:
        return [
          isArabic
              ? 'توليد وطباعة ملصقات الباركود بمقاسات مختلفة (حراري / A4)'
              : 'Custom barcode label generation for thermal & standard printers',
          isArabic
              ? 'دعم ماسحات الباركود اللاسلكية والمسح التلقائي بالكاميرا'
              : 'Support for wireless hand scanners and camera barcode detection',
          isArabic
              ? 'ربط باركودات متعددة للصنف الواحد (تجزئة، كرتون، جملة)'
              : 'Multiple barcodes per item (retail, wholesale, carton)',
          isArabic
              ? 'البحث السريع والفوري عن المنتجات برقم الباركود'
              : 'Instant product search and lookup via barcode',
        ];
      case ComingSoonFeature.invoices:
        return [
          isArabic
              ? 'إصدار فواتير ضريبية ومبسطة متوافقة مع متطلبات الزكاة والدخل (ZATCA)'
              : 'ZATCA Phase-2 compliant electronic tax invoicing',
          isArabic
              ? 'طباعة إيصالات حرارية سريعة مقاس 80 مم وطابعات الشبكة'
              : 'High-speed thermal 80mm and network printer receipts',
          isArabic
              ? 'دعم طرق دفع متعددة (نقداً، شبكة مدى، بطاقات ائتمانية، آجل)'
              : 'Multi-payment methods: Cash, Mada, Credit Cards, and Credit ledger',
          isArabic
              ? 'إدارة مرتجعات المبيعات والخصومات الترويجية بدقة'
              : 'Sales returns, refunds, and automated promotional discounts',
        ];
      case ComingSoonFeature.items:
        return [
          isArabic
              ? 'تصنيف شجري ذكي للأصناف والأقسام مع صور عالية الدقة'
              : 'Hierarchical categories and sub-departments with product media',
          isArabic
              ? 'مصفوفة تسعير متطورة (سعر التكلفة، سعر الجملة، سعر التجزئة)'
              : 'Advanced multi-tier pricing: Cost, Wholesale, and Retail',
          isArabic
              ? 'تنبيهات فورية عند وصول كمية الصنف إلى الحد الأدنى للمخزون'
              : 'Real-time low stock and reorder point threshold alerts',
          isArabic
              ? 'استيراد وتصدير سريع لبيانات المنتجات عبر ملفات Excel و CSV'
              : 'Bulk import and export via Excel spreadsheets and CSV',
        ];
      case ComingSoonFeature.units:
        return [
          isArabic
              ? 'تحديد الوحدة الأساسية والوحدات الفرعية لكل منتج'
              : 'Assign primary base units and packaging sub-units per item',
          isArabic
              ? 'معامل تحويل تلقائي للكميات أثناء عمليات البيع والشراء'
              : 'Automated unit conversion during sales and purchase orders',
          isArabic
              ? 'تسعير مخصص ومستقل لكل وحدة قياس لنفس الصنف'
              : 'Independent pricing rules per packaging unit',
          isArabic
              ? 'دعم الوحدات الوزنية والحجمية مع موازين الباركود'
              : 'Support for weight and volume scale units with barcode scales',
        ];
      case ComingSoonFeature.warehouses:
        return [
          isArabic
              ? 'إدارة المستودعات الرئيسية والفرعية مع ربط الفروع ونقاط البيع'
              : 'Manage master and branch warehouses with POS assignment',
          isArabic
              ? 'إصدار أذونات استلام وصرف وتحويل مخزني بين المستودعات'
              : 'Material receiving, dispatch, and inter-warehouse transfer notes',
          isArabic
              ? 'جرد مخزني دوري وفجائي مع تسوية الفروقات آلياً'
              : 'Periodic & cycle counting audits with automatic variance adjustments',
          isArabic
              ? 'تقارير حركة المخزون التفصيلية وتكلفة البضاعة المباعة (COGS)'
              : 'Detailed stock card ledger and Cost of Goods Sold tracking',
        ];
      case ComingSoonFeature.categories:
        return [
          isArabic
              ? 'شجرة تصنيفات متعددة المستويات (رئيسية وفرعية)'
              : 'Multi-level hierarchical category tree (parent & child)',
          isArabic
              ? 'تخصيص ألوان وأيقونات لكل فئة لتسريع الكاشير'
              : 'Custom colors and icons per category for rapid checkout',
          isArabic
              ? 'تحديد نسب الضريبة والخصومات التلقائية على مستوى الفئة'
              : 'Category-level tax rates and promotional discount rules',
          isArabic
              ? 'إحصائيات المبيعات والأرباح مجمعة حسب الفئة'
              : 'Sales and margin performance aggregated by category',
        ];
      case ComingSoonFeature.financialReports:
        return [
          isArabic
              ? 'قائمة الدخل والأرباح والخسائر الفورية (P&L)'
              : 'Real-time Profit & Loss statement (P&L)',
          isArabic
              ? 'الميزانية العمومية والتدفقات النقدية'
              : 'Balance sheet and statement of cash flows',
          isArabic
              ? 'تقرير الإقرار الضريبي وضريبة القيمة المضافة (VAT)'
              : 'Comprehensive VAT return and tax compliance reports',
          isArabic
              ? 'تصدير التقارير بصيغ PDF و Excel و CSV معتمدة'
              : 'Export certified reports in PDF, Excel, and CSV',
        ];
      case ComingSoonFeature.chartOfAccounts:
        return [
          isArabic
              ? 'ترميز محاسبي قياسي متعدد المستويات (1-الأصول، 2-الخصوم...)'
              : 'Multi-level standard numbering format (1-Assets, 2-Liabilities...)',
          isArabic
              ? 'إضافة وتعديل الحسابات التجميعية والفرعية بسهولة'
              : 'Easily manage header and transactional sub-accounts',
          isArabic
              ? 'ربط الحسابات التلقائي بفواتير المبيعات ونقاط البيع'
              : 'Automatic GL account mapping for POS sales and purchases',
          isArabic
              ? 'تتبع مراكز التكلفة للفروع والمشاريع المستقلة'
              : 'Cost center assignment for independent branches and projects',
        ];
      case ComingSoonFeature.journalEntries:
        return [
          isArabic
              ? 'إنشاء قيود يدوية وتلقائية متوازنة (مدين = دائن)'
              : 'Balanced double-entry journal creation (Debit = Credit)',
          isArabic
              ? 'إرفاق المستندات والعقود الداعمة مع كل قيد'
              : 'Attach supporting invoices, receipts, and documents to entries',
          isArabic
              ? 'سجل تدقيق كامل وتتبع التعديلات وسير الموافقات'
              : 'Complete audit trail, revision history, and approval workflows',
          isArabic
              ? 'الترحيل التلقائي إلى ميزان المراجعة والأستاذ العام'
              : 'Instant automatic posting to General Ledger and Trial Balance',
        ];
      case ComingSoonFeature.transactions:
        return [
          isArabic
              ? 'متابعة سجل المبيعات والمدفوعات لحظة بلحظة'
              : 'Live stream of sales transactions and payment status',
          isArabic
              ? 'إدارة الورديات وجرد الصندوق ومطابقة النقدية (Z-Report)'
              : 'Shift handover, cash drawer reconciliation, and Z-Reports',
          isArabic
              ? 'فلترة متقدمة حسب الفرع، الكاشير، طريقة الدفع، أو التاريخ'
              : 'Filter by branch, cashier operator, payment method, or date range',
          isArabic
              ? 'معالجة المرتجعات والتسويات المالية الفورية'
              : 'Instant refunds, returns, and dispute adjustments',
        ];
      case ComingSoonFeature.dashboard:
        return [
          isArabic
              ? 'مؤشرات مالية حية (إجمالي الإيرادات، المصروفات، وصافي الدخل)'
              : 'Live financial metrics (Gross Revenue, Expenses, Net Profit)',
          isArabic
              ? 'رسوم بيانية تفاعلية لحركة المبيعات ومقارنات الفترات'
              : 'Interactive trend charts and period-over-period comparisons',
          isArabic
              ? 'تنبيهات انخفاض السيولة والمصروفات المستحقة'
              : 'Liquidity warnings and upcoming accounts payable alerts',
          isArabic
              ? 'إحصائيات المنتجات الأكثر مبيعاً والأعلى ربحية'
              : 'Top performing products and highest margin contributors',
        ];
      case ComingSoonFeature.general:
        return null;
    }
  }

  Widget _buildStatusBadge(ThemeData theme, String badge, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkWarningSurface
            : AppTheme.paleOrange,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: AppTheme.warmOrange.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppTheme.warmOrange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            badge,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.darkOrangeAccent : AppTheme.deepOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconContainer(ThemeData theme, IconData iconData, bool isDark) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.12),
            AppTheme.brightBlue.withValues(alpha: isDark ? 0.15 : 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.28),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          iconData,
          size: 42,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildEstimatedReleaseBadge(
      ThemeData theme, String estimated, bool isArabic, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkInformationSurface
            : AppTheme.informationSurface,
        borderRadius: BorderRadius.circular(BkRadius.md),
        border: Border.all(
          color: AppTheme.brightBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 15,
            color: isDark ? AppTheme.darkPrimaryAction : AppTheme.information,
          ),
          const SizedBox(width: 6),
          Text(
            '${isArabic ? 'الموعد المتوقع:' : 'Estimated:'} $estimated',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkPrimaryAction : AppTheme.information,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewPointsSection(
      ThemeData theme, List<String> points, bool isArabic, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BkSpace.md),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surface.withValues(alpha: 0.5)
            : AppTheme.mainBackground,
        borderRadius: BorderRadius.circular(BkRadius.lg),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: AppTheme.warmOrange,
              ),
              const SizedBox(width: 6),
              Text(
                isArabic ? 'ماذا تتوقع في هذا التحديث؟' : 'What to expect:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: BkSpace.sm),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 16,
                    color: AppTheme.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      point,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, ThemeData theme, bool isArabic) {
    if (customAction != null) {
      return customAction!;
    }

    if (!showBackButton) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BkRadius.md),
          ),
          elevation: 0,
        ),
        onPressed: onBack ??
            () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/home');
              }
            },
        icon: Icon(
          isArabic ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
          size: 18,
        ),
        label: Text(
          isArabic ? 'العودة للرئيسية' : 'Back to Dashboard',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }
}

/// Standalone Coming Soon screen wrapper with optional Scaffold and AppBar.
class ComingSoonPage extends StatelessWidget {
  final ComingSoonFeature feature;
  final String? title;
  final String? subtitle;
  final String? badgeText;
  final String? estimatedRelease;
  final IconData? icon;
  final List<String>? previewPoints;
  final VoidCallback? onBack;
  final bool showBackButton;
  final Widget? customAction;
  final bool showAppBar;

  const ComingSoonPage({
    super.key,
    this.feature = ComingSoonFeature.general,
    this.title,
    this.subtitle,
    this.badgeText,
    this.estimatedRelease,
    this.icon,
    this.previewPoints,
    this.onBack,
    this.showBackButton = true,
    this.customAction,
    this.showAppBar = true,
  });

  const ComingSoonPage.barcodes({
    super.key,
    this.title,
    this.subtitle,
    this.badgeText,
    this.estimatedRelease,
    this.icon,
    this.previewPoints,
    this.onBack,
    this.showBackButton = true,
    this.customAction,
    this.showAppBar = true,
  }) : feature = ComingSoonFeature.barcodes;

  const ComingSoonPage.invoices({
    super.key,
    this.title,
    this.subtitle,
    this.badgeText,
    this.estimatedRelease,
    this.icon,
    this.previewPoints,
    this.onBack,
    this.showBackButton = true,
    this.customAction,
    this.showAppBar = true,
  }) : feature = ComingSoonFeature.invoices;

  const ComingSoonPage.items({
    super.key,
    this.title,
    this.subtitle,
    this.badgeText,
    this.estimatedRelease,
    this.icon,
    this.previewPoints,
    this.onBack,
    this.showBackButton = true,
    this.customAction,
    this.showAppBar = true,
  }) : feature = ComingSoonFeature.items;

  const ComingSoonPage.units({
    super.key,
    this.title,
    this.subtitle,
    this.badgeText,
    this.estimatedRelease,
    this.icon,
    this.previewPoints,
    this.onBack,
    this.showBackButton = true,
    this.customAction,
    this.showAppBar = true,
  }) : feature = ComingSoonFeature.units;

  const ComingSoonPage.warehouses({
    super.key,
    this.title,
    this.subtitle,
    this.badgeText,
    this.estimatedRelease,
    this.icon,
    this.previewPoints,
    this.onBack,
    this.showBackButton = true,
    this.customAction,
    this.showAppBar = true,
  }) : feature = ComingSoonFeature.warehouses;

  const ComingSoonPage.categories({
    super.key,
    this.title,
    this.subtitle,
    this.badgeText,
    this.estimatedRelease,
    this.icon,
    this.previewPoints,
    this.onBack,
    this.showBackButton = true,
    this.customAction,
    this.showAppBar = true,
  }) : feature = ComingSoonFeature.categories;

  const ComingSoonPage.financialReports({
    super.key,
    this.title,
    this.subtitle,
    this.badgeText,
    this.estimatedRelease,
    this.icon,
    this.previewPoints,
    this.onBack,
    this.showBackButton = true,
    this.customAction,
    this.showAppBar = true,
  }) : feature = ComingSoonFeature.financialReports;

  const ComingSoonPage.chartOfAccounts({
    super.key,
    this.title,
    this.subtitle,
    this.badgeText,
    this.estimatedRelease,
    this.icon,
    this.previewPoints,
    this.onBack,
    this.showBackButton = true,
    this.customAction,
    this.showAppBar = true,
  }) : feature = ComingSoonFeature.chartOfAccounts;

  const ComingSoonPage.journalEntries({
    super.key,
    this.title,
    this.subtitle,
    this.badgeText,
    this.estimatedRelease,
    this.icon,
    this.previewPoints,
    this.onBack,
    this.showBackButton = true,
    this.customAction,
    this.showAppBar = true,
  }) : feature = ComingSoonFeature.journalEntries;

  const ComingSoonPage.transactions({
    super.key,
    this.title,
    this.subtitle,
    this.badgeText,
    this.estimatedRelease,
    this.icon,
    this.previewPoints,
    this.onBack,
    this.showBackButton = true,
    this.customAction,
    this.showAppBar = true,
  }) : feature = ComingSoonFeature.transactions;

  const ComingSoonPage.dashboard({
    super.key,
    this.title,
    this.subtitle,
    this.badgeText,
    this.estimatedRelease,
    this.icon,
    this.previewPoints,
    this.onBack,
    this.showBackButton = true,
    this.customAction,
    this.showAppBar = true,
  }) : feature = ComingSoonFeature.dashboard;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final resolvedTitle = title ??
        ComingSoonView(feature: feature)._resolveDefaultTitle(isArabic);

    final effectiveOnBack = onBack ??
        () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            context.go('/home');
          }
        };

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: Text(
                resolvedTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              leading: showBackButton
                  ? IconButton(
                      icon: Icon(isArabic
                          ? Icons.arrow_forward_rounded
                          : Icons.arrow_back_rounded),
                      onPressed: effectiveOnBack,
                    )
                  : null,
            )
          : null,
      body: SafeArea(
        child: Center(
          child: ComingSoonView(
            feature: feature,
            title: title,
            subtitle: subtitle,
            badgeText: badgeText,
            estimatedRelease: estimatedRelease,
            icon: icon,
            previewPoints: previewPoints,
            onBack: effectiveOnBack,
            showBackButton: showBackButton,
            customAction: customAction,
          ),
        ),
      ),
    );
  }
}
