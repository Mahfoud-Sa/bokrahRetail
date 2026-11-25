import 'package:bokrah_retail/app/features/companies/domain/entities/company_entity.dart';
import 'package:bokrah_retail/app/features/items/domain/entities/item_entity.dart';
import 'package:equatable/equatable.dart';

enum CompaniesStatus { initial, loading, loaded, error }

class CompaniesState extends Equatable {
  final CompaniesStatus status;
  final List<CompanyEntity> companies;
  final List<ItemEntity> items;
  final CompanyEntity? selectedCompany;
  final List<ItemEntity> linkedItems;
  final bool isSaving;
  final bool isDirectoryLoading;
  final bool isDetailsLoading;
  final String? errorMessage;

  const CompaniesState({
    this.status = CompaniesStatus.initial,
    this.companies = const [],
    this.items = const [],
    this.selectedCompany,
    this.linkedItems = const [],
    this.isSaving = false,
    this.isDirectoryLoading = false,
    this.isDetailsLoading = false,
    this.errorMessage,
  });

  CompaniesState copyWith({
    CompaniesStatus? status,
    List<CompanyEntity>? companies,
    List<ItemEntity>? items,
    CompanyEntity? selectedCompany,
    List<ItemEntity>? linkedItems,
    bool? isSaving,
    bool? isDirectoryLoading,
    bool? isDetailsLoading,
    String? errorMessage,
    bool clearSelectedCompany = false,
    bool clearError = false,
  }) {
    return CompaniesState(
      status: status ?? this.status,
      companies: companies ?? this.companies,
      items: items ?? this.items,
      selectedCompany: clearSelectedCompany
          ? null
          : (selectedCompany ?? this.selectedCompany),
      linkedItems: linkedItems ?? this.linkedItems,
      isSaving: isSaving ?? this.isSaving,
      isDirectoryLoading: isDirectoryLoading ?? this.isDirectoryLoading,
      isDetailsLoading: isDetailsLoading ?? this.isDetailsLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    companies,
    items,
    selectedCompany,
    linkedItems,
    isSaving,
    isDirectoryLoading,
    isDetailsLoading,
    errorMessage,
  ];
}
