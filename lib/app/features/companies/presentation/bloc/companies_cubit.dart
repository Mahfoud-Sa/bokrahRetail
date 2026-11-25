import 'package:bokrah_retail/app/features/companies/domain/entities/company_entity.dart';
import 'package:bokrah_retail/app/features/companies/domain/usecases/company_usecases.dart';
import 'package:bokrah_retail/app/features/companies/presentation/bloc/companies_state.dart';
import 'package:bokrah_retail/app/features/items/data/services/items_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CompaniesCubit extends Cubit<CompaniesState> {
  final GetAllCompaniesUseCase _getAllCompanies;
  final GetCompanyByIdUseCase _getCompanyById;
  final SaveCompanyUseCase _saveCompany;
  final UpdateCompanyUseCase _updateCompany;
  final DeleteCompanyUseCase _deleteCompany;
  final ItemsService _itemsService;

  CompaniesCubit({
    required GetAllCompaniesUseCase getAllCompanies,
    required GetCompanyByIdUseCase getCompanyById,
    required SaveCompanyUseCase saveCompany,
    required UpdateCompanyUseCase updateCompany,
    required DeleteCompanyUseCase deleteCompany,
    required ItemsService itemsService,
  }) : _getAllCompanies = getAllCompanies,
       _getCompanyById = getCompanyById,
       _saveCompany = saveCompany,
       _updateCompany = updateCompany,
       _deleteCompany = deleteCompany,
       _itemsService = itemsService,
       super(const CompaniesState());

  Future<void> loadCompanies() async {
    emit(state.copyWith(status: CompaniesStatus.loading, clearError: true));
    try {
      final companiesFuture = _getAllCompanies();
      final itemsFuture = _itemsService.getAllItems();
      final companies = await companiesFuture;
      final items = await itemsFuture;
      emit(
        state.copyWith(
          status: CompaniesStatus.loaded,
          companies: companies,
          items: items,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: CompaniesStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> loadCompanyDirectory() async {
    emit(state.copyWith(isDirectoryLoading: true, clearError: true));
    try {
      final companies = await _getAllCompanies();
      emit(
        state.copyWith(
          companies: companies,
          isDirectoryLoading: false,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isDirectoryLoading: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<bool> loadCompanyDetails(int id) async {
    emit(
      state.copyWith(
        isDetailsLoading: true,
        clearSelectedCompany: true,
        linkedItems: const [],
        clearError: true,
      ),
    );
    try {
      final company = await _getCompanyById(id);
      if (company == null) {
        emit(
          state.copyWith(
            isDetailsLoading: false,
            errorMessage: 'Company not found',
          ),
        );
        return false;
      }

      final items = await _itemsService.getAllItems();
      final linkedItems = items.where((item) {
        final itemCompany = item.effectiveCompany ?? '';
        final itemBrand = item.brand ?? '';
        return (itemCompany.isNotEmpty && company.matchesName(itemCompany)) ||
            (itemBrand.isNotEmpty && company.hasBrand(itemBrand));
      }).toList();

      emit(
        state.copyWith(
          selectedCompany: company,
          linkedItems: linkedItems,
          items: items,
          isDetailsLoading: false,
          clearError: true,
        ),
      );
      return true;
    } catch (error) {
      emit(
        state.copyWith(isDetailsLoading: false, errorMessage: error.toString()),
      );
      return false;
    }
  }

  Future<CompanyEntity?> saveCompany(CompanyEntity company) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    try {
      final saved = await _saveCompany(company);
      if (saved == null) {
        emit(state.copyWith(isSaving: false));
        return null;
      }

      emit(
        state.copyWith(
          companies: [...state.companies, saved],
          isSaving: false,
          clearError: true,
        ),
      );
      return saved;
    } catch (error) {
      emit(state.copyWith(isSaving: false, errorMessage: error.toString()));
      return null;
    }
  }

  Future<bool> updateCompany(CompanyEntity company) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    try {
      final updated = await _updateCompany(company);
      if (updated) {
        emit(
          state.copyWith(
            companies: state.companies
                .map((current) => current.id == company.id ? company : current)
                .toList(),
            selectedCompany: company,
            isSaving: false,
            clearError: true,
          ),
        );
      } else {
        emit(state.copyWith(isSaving: false));
      }
      return updated;
    } catch (error) {
      emit(state.copyWith(isSaving: false, errorMessage: error.toString()));
      return false;
    }
  }

  Future<bool> deleteCompany(int id) async {
    try {
      final success = await _deleteCompany(id);
      if (success) {
        emit(
          state.copyWith(
            companies: state.companies
                .where((company) => company.id != id)
                .toList(),
            clearSelectedCompany: state.selectedCompany?.id == id,
            linkedItems: state.selectedCompany?.id == id ? const [] : null,
          ),
        );
      }
      return success;
    } catch (error) {
      emit(state.copyWith(errorMessage: error.toString()));
      return false;
    }
  }

  Future<void> refresh() => loadCompanies();
}
