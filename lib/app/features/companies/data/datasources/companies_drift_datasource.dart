import 'dart:convert';

import 'package:bokrah_retail/app/core/database/app_database.dart';
import 'package:bokrah_retail/app/features/companies/data/datasources/companies_local_datasource.dart';
import 'package:bokrah_retail/app/features/companies/data/models/company_model.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drift/SQLite-backed implementation of [CompaniesLocalDataSource].
///
/// Stores companies locally in SQLite and supports one-time migration from
/// legacy `SharedPreferences` (`companies_list`) as well as cloud sync updates.
class CompaniesDriftDataSource implements CompaniesLocalDataSource {
  static const String _legacyPrefsKey = 'companies_list';
  static const String _seededKey = 'companies_drift_seeded';

  final AppDatabase _db;
  final SharedPreferences? _prefs;
  bool _initialized = false;

  CompaniesDriftDataSource({
    required AppDatabase database,
    SharedPreferences? prefs,
  })  : _db = database,
        _prefs = prefs;

  Future<void> _ensureSeededOrMigrated() async {
    if (_initialized) return;
    _initialized = true;

    final existing = await _db.select(_db.companies).get();
    if (existing.isNotEmpty) return;

    final prefs = _prefs ?? await SharedPreferences.getInstance();
    if (prefs.containsKey(_legacyPrefsKey)) {
      final legacyJson = prefs.getStringList(_legacyPrefsKey) ?? const [];
      if (legacyJson.isNotEmpty) {
        await _db.batch((batch) {
          for (final raw in legacyJson) {
            final map = json.decode(raw) as Map<String, dynamic>;
            final model = CompanyModel.fromMap(map);
            batch.insert(
              _db.companies,
              _toCompanion(model, includeId: model.id != null),
              mode: InsertMode.insertOrReplace,
            );
          }
        });
        await prefs.setBool(_seededKey, true);
        return;
      }
    }

    if (prefs.getBool(_seededKey) != true) {
      final defaults = _defaultCompanies();
      await _db.batch((batch) {
        for (final company in defaults) {
          batch.insert(
            _db.companies,
            _toCompanion(company, includeId: true),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
      await prefs.setBool(_seededKey, true);
    }
  }

  @override
  Future<List<CompanyModel>> getAllCompanies() async {
    await _ensureSeededOrMigrated();
    final rows = await _db.select(_db.companies).get();
    return rows.map(_fromRow).toList();
  }

  @override
  Future<CompanyModel?> getCompanyById(int id) async {
    await _ensureSeededOrMigrated();
    final row = await (_db.select(_db.companies)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _fromRow(row) : null;
  }

  @override
  Future<CompanyModel?> saveCompany(CompanyModel company) async {
    try {
      await _ensureSeededOrMigrated();
      final insertedId = await _db.into(_db.companies).insert(
            _toCompanion(company, includeId: company.id != null),
            mode: InsertMode.insertOrReplace,
          );
      return getCompanyById(company.id ?? insertedId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> updateCompany(CompanyModel company) async {
    if (company.id == null) return false;
    try {
      await _ensureSeededOrMigrated();
      final updatedCount = await (_db.update(_db.companies)
            ..where((t) => t.id.equals(company.id!)))
          .write(_toCompanion(company, includeId: false));
      return updatedCount > 0;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> deleteCompany(int id) async {
    try {
      await _ensureSeededOrMigrated();
      final deletedCount = await (_db.delete(_db.companies)
            ..where((t) => t.id.equals(id)))
          .go();
      return deletedCount > 0;
    } catch (_) {
      return false;
    }
  }

  /// Upserts a canonical server-synced company record, replacing [localId]
  /// when the backend assigns a new ID.
  Future<void> upsertSyncedCompany({
    required int localId,
    required CompanyModel canonical,
  }) async {
    await _db.transaction(() async {
      if (canonical.id != null && canonical.id != localId) {
        await (_db.delete(_db.companies)..where((t) => t.id.equals(localId)))
            .go();
      }
      await _db.into(_db.companies).insert(
            _toCompanion(canonical, includeId: canonical.id != null, isSynced: true),
            mode: InsertMode.insertOrReplace,
          );
    });
  }

  /// Merges pulled server records into Drift while preserving any companies
  /// with pending local outbox edits ([protectedLocalIds]).
  Future<int> mergePulledCompanies({
    required List<CompanyModel> pulled,
    required Set<int> protectedLocalIds,
  }) async {
    if (pulled.isEmpty) return 0;
    await _ensureSeededOrMigrated();

    await _db.transaction(() async {
      final existing = await _db.select(_db.companies).get();
      for (final row in existing) {
        if (!protectedLocalIds.contains(row.id)) {
          await (_db.delete(_db.companies)..where((t) => t.id.equals(row.id)))
              .go();
        }
      }
      for (final company in pulled) {
        if (company.id != null && protectedLocalIds.contains(company.id)) {
          continue;
        }
        await _db.into(_db.companies).insert(
              _toCompanion(
                company,
                includeId: company.id != null,
                isSynced: true,
              ),
              mode: InsertMode.insertOrReplace,
            );
      }
    });

    return pulled.length;
  }

  CompanyModel _fromRow(CompanyRow row) {
    final brands = (json.decode(row.brandsJson) as List<dynamic>)
        .map((e) => e.toString())
        .toList();
    return CompanyModel(
      id: row.id,
      name: row.name,
      arabicName: row.arabicName,
      englishName: row.englishName,
      brands: brands,
      image: row.image,
      imageBytes: row.imageBytes,
      code: row.code,
      description: row.description,
      website: row.website,
      email: row.email,
      phone: row.phone,
      address: row.address,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  CompaniesCompanion _toCompanion(
    CompanyModel company, {
    required bool includeId,
    bool isSynced = false,
  }) {
    return CompaniesCompanion(
      id: includeId && company.id != null
          ? Value(company.id!)
          : const Value.absent(),
      name: Value(company.name),
      arabicName: Value(company.arabicName),
      englishName: Value(company.englishName),
      brandsJson: Value(json.encode(company.brands)),
      image: Value(company.image),
      imageBytes: Value(company.imageBytes),
      code: Value(company.code),
      description: Value(company.description),
      website: Value(company.website),
      email: Value(company.email),
      phone: Value(company.phone),
      address: Value(company.address),
      createdAt: Value(company.createdAt),
      updatedAt: Value(company.updatedAt),
      isSynced: Value(isSynced),
    );
  }

  List<CompanyModel> _defaultCompanies() {
    return [
      CompanyModel(
        id: 101,
        name: 'Apple',
        arabicName: 'أبل',
        englishName: 'Apple Inc.',
        code: 'AAPL',
        image:
            'https://upload.wikimedia.org/wikipedia/commons/f/fa/Apple_logo_black.svg',
        brands: ['iPhone', 'iPad', 'MacBook', 'Apple Watch', 'AirPods'],
        description:
            'شركة تقنية أمريكية متعددة الجنسيات متخصصة في الإلكترونيات الاستهلاكية والبرمجيات.',
        website: 'https://www.apple.com',
        email: 'contact@apple.com',
        phone: '+1 800-692-7753',
        address: 'Cupertino, California, USA',
      ),
      CompanyModel(
        id: 102,
        name: 'Samsung',
        arabicName: 'سامسونج',
        englishName: 'Samsung Electronics',
        code: 'SAMS',
        image:
            'https://upload.wikimedia.org/wikipedia/commons/2/24/Samsung_Logo.svg',
        brands: ['Galaxy', 'Odyssey', 'Neo QLED', 'SmartThings', 'Galaxy Watch'],
        description:
            'تكتل كوري جنوبي رائد في تصنيع الإلكترونيات وشاشات العرض وأجهزة المحمول.',
        website: 'https://www.samsung.com',
        email: 'support@samsung.com',
        phone: '+82 2-2053-3000',
        address: 'Suwon, South Korea',
      ),
      CompanyModel(
        id: 103,
        name: 'Sony',
        arabicName: 'سوني',
        englishName: 'Sony Corporation',
        code: 'SONY',
        image:
            'https://upload.wikimedia.org/wikipedia/commons/c/ca/Sony_logo.svg',
        brands: ['PlayStation', 'Bravia', 'Xperia', 'Alpha'],
        description:
            'شركة يابانية رائدة في مجال الإلكترونيات وألعاب الفيديو والمعدات الترفيهية.',
        website: 'https://www.sony.com',
        email: 'info@sony.com',
        phone: '+81 3-6748-2111',
        address: 'Minato, Tokyo, Japan',
      ),
      CompanyModel(
        id: 104,
        name: 'Almarai',
        arabicName: 'المراعي',
        englishName: 'Almarai Company',
        code: 'ALMR',
        image:
            'https://upload.wikimedia.org/wikipedia/en/thumb/d/d4/Almarai_logo.svg/330px-Almarai_logo.svg.png',
        brands: [
          'المراعي (Almarai)',
          "لوزين (L'usine)",
          'سفن دايز (7 Days)',
          'نيورالاك (Nuralac)',
          'بيتي (Beyti)',
        ],
        description:
            'الشركة الرائدة في صناعة الأغذية والمشروبات ومنتجات الألبان في الشرق الأوسط.',
        website: 'https://www.almarai.com',
        email: 'info@almarai.com',
        phone: '+966 11 470 0005',
        address: 'Riyadh, Saudi Arabia',
      ),
      CompanyModel(
        id: 105,
        name: 'Unilever',
        arabicName: 'يونيليفر',
        englishName: 'Unilever',
        code: 'ULVR',
        image:
            'https://upload.wikimedia.org/wikipedia/en/thumb/8/87/Unilever.svg/330px-Unilever.svg.png',
        brands: [
          'Dove',
          'Lipton',
          'Sunsilk',
          'Lifebuoy',
          'Knorr',
          'Rexona',
          'Axe',
        ],
        description:
            'إحدى كبرى الشركات العالمية في إنتاج السلع الاستهلاكية ومستحضرات العناية الشخصية والمنزلية.',
        website: 'https://www.unilever.com',
        email: 'contact@unilever.com',
        phone: '+44 20 7822 5252',
        address: 'London, United Kingdom',
      ),
    ];
  }
}
