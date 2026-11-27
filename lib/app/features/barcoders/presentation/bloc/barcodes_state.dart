import 'package:bokrah_retail/app/features/barcoders/domain/entities/barcode_entity.dart';
import 'package:bokrah_retail/app/features/items/domain/entities/item_entity.dart';
import 'package:equatable/equatable.dart';

enum BarcodesStatus { initial, loading, loaded, error }

class BarcodesState extends Equatable {
  final BarcodesStatus status;
  final List<BarcodeEntity> barcodes;
  final List<ItemEntity> allItems;
  final Map<int, List<ItemEntity>> relatedItems;
  final bool isSaving;
  final String? errorMessage;

  const BarcodesState({
    this.status = BarcodesStatus.initial,
    this.barcodes = const [],
    this.allItems = const [],
    this.relatedItems = const {},
    this.isSaving = false,
    this.errorMessage,
  });

  BarcodesState copyWith({
    BarcodesStatus? status,
    List<BarcodeEntity>? barcodes,
    List<ItemEntity>? allItems,
    Map<int, List<ItemEntity>>? relatedItems,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BarcodesState(
      status: status ?? this.status,
      barcodes: barcodes ?? this.barcodes,
      allItems: allItems ?? this.allItems,
      relatedItems: relatedItems ?? this.relatedItems,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    barcodes,
    allItems,
    relatedItems,
    isSaving,
    errorMessage,
  ];
}
