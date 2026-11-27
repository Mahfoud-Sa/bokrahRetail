import 'package:equatable/equatable.dart';
import 'package:bokrah_retail/app/features/categories/domain/entities/category_entity.dart';
import 'package:bokrah_retail/app/features/items/domain/entities/item_entity.dart';

enum CategoriesStatus { initial, loading, loaded, error }

class CategoriesState extends Equatable {
  final CategoriesStatus status;
  final List<CategoryEntity> categories;
  final List<ItemEntity> items;
  final Set<int> expandedCategoryIds;
  final bool isSaving;
  final String? errorMessage;

  const CategoriesState({
    this.status = CategoriesStatus.initial,
    this.categories = const [],
    this.items = const [],
    this.expandedCategoryIds = const {},
    this.isSaving = false,
    this.errorMessage,
  });

  CategoriesState copyWith({
    CategoriesStatus? status,
    List<CategoryEntity>? categories,
    List<ItemEntity>? items,
    Set<int>? expandedCategoryIds,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CategoriesState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      items: items ?? this.items,
      expandedCategoryIds: expandedCategoryIds ?? this.expandedCategoryIds,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    categories,
    items,
    expandedCategoryIds,
    isSaving,
    errorMessage,
  ];
}
