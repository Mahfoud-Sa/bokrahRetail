import 'package:bokrah_design_system/bokrah_design_system.dart';
import 'package:bokrah_retail/app/config/l10n/app_localizations.dart';
import 'package:bokrah_retail/app/config/routes.dart';
import 'package:bokrah_retail/app/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:bokrah_retail/app/features/autoUpdate/presentation/cubits/app_update_cubit.dart';
import 'package:bokrah_retail/app/features/store/presentation/cubits/store_cubit.dart';
import 'package:bokrah_retail/app/features/restaurant/presentation/cubits/restaurant_cubit.dart';
import 'package:bokrah_retail/app/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:bokrah_retail/app/features/settings/presentation/cubits/settings_cubit.dart';
import 'package:bokrah_retail/app/features/settings/presentation/cubits/settings_state.dart';
import 'package:bokrah_retail/app/features/users/presentation/cubits/session_cubit.dart';
import 'package:bokrah_retail/app/initialzation_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializationDependencies();
  final prefs = await SharedPreferences.getInstance();
  final packageInfo = await PackageInfo.fromPlatform();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => SettingsCubit(
            localDataSource: SettingsLocalDataSource(sharedPreferences: prefs),
          ),
        ),
        BlocProvider(create: (context) => singelton<AuthCubit>()),
        BlocProvider(create: (context) => singelton<AppUpdateCubit>()),
        BlocProvider(create: (context) => singelton<SessionCubit>()),
        BlocProvider(
          create: (context) => singelton<StoreCubit>()..loadStore(),
        ),
      ],
      child: Bokrah(packageInfo: packageInfo),
    ),
  );
}

class Bokrah extends StatelessWidget {
  final PackageInfo packageInfo;

  const Bokrah({super.key, required this.packageInfo});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final isArabic = state.locale.languageCode == 'ar';
        final light = state.isHighContrast
            ? BkTheme.highContrast(arabic: isArabic)
            : BkTheme.light(arabic: isArabic);
        final dark = state.isHighContrast
            ? BkTheme.dark(arabic: isArabic)
            : BkTheme.dark(arabic: isArabic);

        return MaterialApp.router(
          debugShowMaterialGrid: false,
          title: packageInfo.appName.isEmpty ? 'Bokra Retail' : packageInfo.appName,
          theme: light,
          darkTheme: dark,
          highContrastTheme: BkTheme.highContrast(arabic: isArabic),
          highContrastDarkTheme: BkTheme.highContrast(arabic: isArabic),
          themeMode: state.themeMode,
          locale: state.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: AppRoutes.routers,
        );
      },
    );
  }
}

class BokrahRetailApp extends StatelessWidget {
  const BokrahRetailApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Bokra Retail',
    debugShowCheckedModeBanner: false,
    theme: RetailTheme.light(),
    home: const RetailWorkspace(),
  );
}

abstract final class RetailTheme {
  static const forest = Color(0xFF183B35);
  static const amber = Color(0xFFD69B45);
  static const canvas = Color(0xFFF3F5F1);

  static ThemeData light() {
    final base = BkTheme.light();
    final scheme = base.colorScheme.copyWith(
      primary: forest,
      onPrimary: Colors.white,
      secondary: amber,
      onSecondary: const Color(0xFF2B1B06),
      surface: Colors.white,
      onSurface: const Color(0xFF17211F),
      surfaceContainerLow: const Color(0xFFE8EDE7),
      outline: const Color(0xFFB8C5BD),
    );
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: Colors.white,
        foregroundColor: scheme.onSurface,
      ),
      dividerColor: const Color(0xFFD8E0DA),
    );
  }
}

class RetailWorkspace extends StatefulWidget {
  const RetailWorkspace({super.key});

  @override
  State<RetailWorkspace> createState() => _RetailWorkspaceState();
}

class _RetailWorkspaceState extends State<RetailWorkspace> {
  var selectedIndex = 0;
  final products = <RetailProduct>[
    const RetailProduct(
      name: 'Canvas Tote',
      sku: 'BKR-001',
      price: 'JOD 18.00',
      stock: 24,
    ),
    const RetailProduct(
      name: 'Everyday Notebook',
      sku: 'BKR-002',
      price: 'JOD 7.50',
      stock: 8,
    ),
    const RetailProduct(
      name: 'Amber Candle',
      sku: 'BKR-003',
      price: 'JOD 16.00',
      stock: 4,
    ),
  ];

  static const navigationItems = [
    BkNavigationItem(label: 'Overview', icon: Icons.space_dashboard_outlined),
    BkNavigationItem(label: 'Catalog', icon: Icons.inventory_2_outlined),
    BkNavigationItem(label: 'Orders', icon: Icons.receipt_long_outlined),
    BkNavigationItem(label: 'Customers', icon: Icons.people_outline),
    BkNavigationItem(label: 'Reports', icon: Icons.insights_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 920;
    return Scaffold(
      appBar: BkAppBar(
        title: navigationItems[selectedIndex].label,
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_outlined),
          ),
          const SizedBox(width: BkSpace.sm),
        ],
      ),
      drawer: compact
          ? BkNavigationDrawer(
              label: 'Bokra Retail',
              items: navigationItems,
              selectedIndex: selectedIndex,
              onSelected: _select,
            )
          : null,
      body: Row(
        children: [
          if (!compact)
            SizedBox(
              width: 244,
              child: BkSidebar(
                label: 'Bokra Retail',
                items: navigationItems,
                selectedIndex: selectedIndex,
                onSelected: _select,
              ),
            ),
          Expanded(child: _pageFor(selectedIndex)),
        ],
      ),
    );
  }

  void _select(int index) => setState(() => selectedIndex = index);

  Widget _pageFor(int index) => switch (index) {
    0 => RetailOverview(onOpenCatalog: () => _select(1)),
    1 => RetailCatalog(products: products, onProductAdded: _addProduct),
    _ => RetailPlaceholder(title: navigationItems[index].label),
  };

  void _addProduct(RetailProduct product) {
    setState(() => products.add(product));
  }
}

class RetailOverview extends StatelessWidget {
  const RetailOverview({super.key, required this.onOpenCatalog});

  final VoidCallback onOpenCatalog;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(BkSpace.xl),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1320),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good morning',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: BkSpace.sm),
          Text(
            'Your retail workspace is ready to manage products, sales, and customers.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: BkSpace.xl),
          const Wrap(
            spacing: BkSpace.lg,
            runSpacing: BkSpace.lg,
            children: [
              SizedBox(
                width: 248,
                child: BkStatCard(label: 'Today’s sales', value: '—'),
              ),
              SizedBox(
                width: 248,
                child: BkStatCard(label: 'Orders', value: '—', tinted: true),
              ),
              SizedBox(
                width: 248,
                child: BkStatCard(label: 'Low stock', value: '—'),
              ),
            ],
          ),
          const SizedBox(height: BkSpace.xxl),
          BkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start building your store',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: BkSpace.sm),
                const Text(
                  'Add your first product, then connect order and customer workflows.',
                ),
                const SizedBox(height: BkSpace.lg),
                BkButton(
                  label: 'Open catalog',
                  icon: Icons.inventory_2_outlined,
                  onPressed: onOpenCatalog,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class RetailCatalog extends StatelessWidget {
  const RetailCatalog({
    super.key,
    required this.products,
    required this.onProductAdded,
  });

  final List<RetailProduct> products;
  final ValueChanged<RetailProduct> onProductAdded;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(BkSpace.xl),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1320),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product catalog',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: BkSpace.sm),
                    Text(
                      '${products.length} products ready for your store.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              BkButton(
                label: 'Add product',
                icon: Icons.add,
                onPressed: () => _showAddProductDialog(context),
              ),
            ],
          ),
          const SizedBox(height: BkSpace.xl),
          Wrap(
            spacing: BkSpace.lg,
            runSpacing: BkSpace.lg,
            children: [
              for (final product in products)
                SizedBox(
                  width: 292,
                  child: BkCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BkBadge(
                          label: product.stock <= 5 ? 'Low stock' : 'In stock',
                          tone: product.stock <= 5
                              ? BkTone.warning
                              : BkTone.success,
                        ),
                        const SizedBox(height: BkSpace.lg),
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: BkSpace.sm),
                        Text(
                          product.sku,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: BkSpace.lg),
                        Wrap(
                          spacing: BkSpace.md,
                          runSpacing: BkSpace.sm,
                          children: [
                            Text(
                              product.price,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text('${product.stock} in stock'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _showAddProductDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final skuController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add product'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BkTextField(label: 'Product name', controller: nameController),
              const SizedBox(height: BkSpace.md),
              BkTextField(label: 'SKU', controller: skuController),
              const SizedBox(height: BkSpace.md),
              BkTextField(label: 'Price', controller: priceController),
              const SizedBox(height: BkSpace.md),
              BkTextField(
                label: 'Stock quantity',
                controller: stockController,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          BkButton(
            label: 'Add product',
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              onProductAdded(
                RetailProduct(
                  name: name,
                  sku: skuController.text.trim().isEmpty
                      ? 'BKR-${(products.length + 1).toString().padLeft(3, '0')}'
                      : skuController.text.trim(),
                  price: priceController.text.trim().isEmpty
                      ? 'JOD 0.00'
                      : priceController.text.trim(),
                  stock: int.tryParse(stockController.text.trim()) ?? 0,
                ),
              );
              Navigator.pop(dialogContext);
            },
          ),
        ],
      ),
    );

    nameController.dispose();
    skuController.dispose();
    priceController.dispose();
    stockController.dispose();
  }
}

class RetailProduct {
  const RetailProduct({
    required this.name,
    required this.sku,
    required this.price,
    required this.stock,
  });

  final String name;
  final String sku;
  final String price;
  final int stock;
}

class RetailPlaceholder extends StatelessWidget {
  const RetailPlaceholder({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Center(
    child: BkEmptyState(
      title: '$title is coming next',
      message: 'This foundation is ready for the dedicated $title workflow.',
    ),
  );
}
