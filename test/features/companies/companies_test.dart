import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bokrah_retail/app/features/companies/domain/entities/company_entity.dart';
import 'package:bokrah_retail/app/features/companies/data/models/company_model.dart';
import 'package:bokrah_retail/app/features/companies/data/datasources/companies_local_datasource.dart';
import 'package:bokrah_retail/app/features/companies/data/repositories/companies_repository_impl.dart';
import 'package:bokrah_retail/app/features/companies/data/services/companies_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CompanyEntity & CompanyModel', () {
    test('creates entity and model properly with default values and auto-derived name', () {
      final company = CompanyEntity(
        id: 1,
        arabicName: 'أبل',
        englishName: 'Apple Inc.',
        brands: ['iPhone', 'iPad'],
        image: 'https://example.com/apple.png',
        code: 'AAPL',
      );

      expect(company.id, 1);
      expect(company.name, 'Apple Inc.'); // auto-derived from englishName
      expect(company.arabicName, 'أبل');
      expect(company.englishName, 'Apple Inc.');
      expect(company.brands, ['iPhone', 'iPad']);
      expect(company.image, 'https://example.com/apple.png');
      expect(company.code, 'AAPL');
      expect(company.localizedName(true), 'أبل');
      expect(company.localizedName(false), 'Apple Inc.');
    });

    test('domain methods matchesName, matches, and hasBrand work accurately', () {
      final company = CompanyEntity(
        id: 2,
        name: 'Samsung',
        arabicName: 'سامسونج',
        englishName: 'Samsung Electronics',
        brands: ['Galaxy', 'Odyssey', 'Neo QLED'],
        code: 'SAMS',
      );

      // matchesName
      expect(company.matchesName('samsung'), isTrue);
      expect(company.matchesName('سامسونج'), isTrue);
      expect(company.matchesName('Samsung Electronics'), isTrue);
      expect(company.matchesName('Sony'), isFalse);

      // hasBrand
      expect(company.hasBrand('galaxy'), isTrue);
      expect(company.hasBrand('Neo QLED'), isTrue);
      expect(company.hasBrand('PlayStation'), isFalse);

      // matches (free-text search)
      expect(company.matches('sams'), isTrue);
      expect(company.matches('galaxy'), isTrue);
      expect(company.matches('سامس'), isTrue);
      expect(company.matches('unknown'), isFalse);
    });

    test('toMap and fromMap serialize and deserialize correctly', () {
      final model = CompanyModel(
        id: 42,
        name: 'Samsung',
        arabicName: 'سامسونج',
        englishName: 'Samsung Electronics',
        brands: ['Galaxy', 'Odyssey'],
        image: 'https://example.com/samsung.png',
        code: 'SAMS',
        description: 'Tech giant',
        website: 'https://samsung.com',
        email: 'info@samsung.com',
        phone: '123456789',
        address: 'Korea',
      );

      final map = model.toMap();
      final reconstructed = CompanyModel.fromMap(map);

      expect(reconstructed.id, 42);
      expect(reconstructed.name, 'Samsung');
      expect(reconstructed.arabicName, 'سامسونج');
      expect(reconstructed.englishName, 'Samsung Electronics');
      expect(reconstructed.brands, ['Galaxy', 'Odyssey']);
      expect(reconstructed.image, 'https://example.com/samsung.png');
      expect(reconstructed.code, 'SAMS');
      expect(reconstructed.website, 'https://samsung.com');
      expect(reconstructed.email, 'info@samsung.com');
      expect(reconstructed.phone, '123456789');
      expect(reconstructed.address, 'Korea');
    });

    test('copyWith updates properties properly', () {
      final original = CompanyEntity(
        id: 1,
        name: 'Sony',
        arabicName: 'سوني',
        englishName: 'Sony Corp',
        brands: ['PlayStation'],
      );

      final updated = original.copyWith(
        brands: ['PlayStation', 'Bravia'],
        code: 'SONY',
      );

      expect(updated.id, 1);
      expect(updated.name, 'Sony');
      expect(updated.brands, ['PlayStation', 'Bravia']);
      expect(updated.code, 'SONY');
    });
  });

  group('CompaniesService & Repository Integration', () {
    late SharedPreferences prefs;
    late CompaniesLocalDataSource dataSource;
    late CompaniesRepositoryImpl repository;
    late CompaniesService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      dataSource = CompaniesLocalDataSourceImpl(prefs: prefs);
      repository = CompaniesRepositoryImpl(localDataSource: dataSource);
      service = CompaniesService(repository: repository);
    });

    test('returns empty list if storage is empty', () async {
      final companies = await service.getAllCompanies();
      expect(companies, isEmpty);
    });

    test('remains empty after every company is deleted', () async {
      final saved = await service.saveCompany(
        CompanyEntity(
          name: 'Temp Co',
          arabicName: 'شركة مؤقتة',
          englishName: 'Temp Co',
          brands: ['Brand1'],
        ),
      );
      expect(saved, isNotNull);
      expect(await service.deleteCompany(saved!.id!), isTrue);

      final remaining = await service.getAllCompanies();
      expect(remaining, isEmpty);
    });

    test('saves and retrieves a new company', () async {
      final newComp = CompanyEntity(
        name: 'Dell',
        arabicName: 'ديل',
        englishName: 'Dell Technologies',
        brands: ['Alienware', 'Latitude', 'XPS'],
        code: 'DELL',
      );

      final saved = await service.saveCompany(newComp);
      expect(saved, isNotNull);
      expect(saved!.id, isNotNull);
      expect(saved.name, 'Dell');
      expect(saved.brands, ['Alienware', 'Latitude', 'XPS']);

      final all = await service.getAllCompanies();
      expect(all.any((c) => c.name == 'Dell'), isTrue);
    });

    test('findMatchingCompany and getBrandsForCompany resolve correctly', () async {
      await service.saveCompany(
        CompanyEntity(
          id: 1,
          name: 'Apple',
          arabicName: 'أبل',
          englishName: 'Apple Inc.',
          brands: ['iPhone', 'iPad'],
        ),
      );

      final all = await service.getAllCompanies();
      final match = service.findMatchingCompany(all, 'أبل');
      expect(match, isNotNull);
      expect(match!.name, 'Apple');

      final brands = service.getBrandsForCompany(all, 'Apple');
      expect(brands.contains('iPhone'), isTrue);
      expect(brands.contains('iPad'), isTrue);
    });

    test('updates an existing company', () async {
      await service.saveCompany(
        CompanyEntity(
          id: 1,
          name: 'Apple',
          arabicName: 'أبل',
          englishName: 'Apple Inc.',
          brands: ['iPhone'],
        ),
      );

      final companies = await service.getAllCompanies();
      final target = companies.first;

      final updated = target.copyWith(
        brands: [...target.brands, 'NewBrand'],
      );

      final success = await service.updateCompany(updated);
      expect(success, isTrue);

      final fetched = await service.getCompanyById(target.id!);
      expect(fetched, isNotNull);
      expect(fetched!.brands.contains('NewBrand'), isTrue);
    });

    test('deletes a company', () async {
      await service.saveCompany(
        CompanyEntity(
          id: 1,
          name: 'Apple',
          arabicName: 'أبل',
          englishName: 'Apple Inc.',
          brands: ['iPhone'],
        ),
      );

      final companies = await service.getAllCompanies();
      final target = companies.first;
      final initialCount = companies.length;

      final success = await service.deleteCompany(target.id!);
      expect(success, isTrue);

      final after = await service.getAllCompanies();
      expect(after.length, initialCount - 1);
      expect(after.any((c) => c.id == target.id), isFalse);
    });

    test('searchCompanies filters by name, arabic name, english name, and brands', () async {
      final list = [
        CompanyEntity(
          id: 1,
          name: 'Apple',
          arabicName: 'أبل',
          englishName: 'Apple Inc.',
          brands: ['iPhone', 'MacBook'],
          code: 'AAPL',
        ),
        CompanyEntity(
          id: 2,
          name: 'Almarai',
          arabicName: 'المراعي',
          englishName: 'Almarai Company',
          brands: ['Lusine', '7 Days'],
          code: 'ALMR',
        ),
      ];

      // Search by English name
      expect(service.searchCompanies(list, 'Apple').length, 1);
      // Search by Arabic name
      expect(service.searchCompanies(list, 'المراعي').length, 1);
      // Search by Brand
      expect(service.searchCompanies(list, 'iPhone').length, 1);
      expect(service.searchCompanies(list, 'Lusine').length, 1);
      // Search by Code
      expect(service.searchCompanies(list, 'ALMR').length, 1);
      // Non-matching query
      expect(service.searchCompanies(list, 'NonExistent').length, 0);
    });

    test('getAllBrands collects unique sorted brands', () async {
      await service.saveCompany(
        CompanyEntity(
          id: 1,
          name: 'Apple',
          arabicName: 'أبل',
          englishName: 'Apple Inc.',
          brands: ['iPhone', 'iPad'],
        ),
      );
      await service.saveCompany(
        CompanyEntity(
          id: 2,
          name: 'Samsung',
          arabicName: 'سامسونج',
          englishName: 'Samsung Electronics',
          brands: ['Galaxy', 'iPhone'],
        ),
      );

      final brands = await service.getAllBrands();
      expect(brands, ['Galaxy', 'iPad', 'iPhone']);
    });
  });
}
