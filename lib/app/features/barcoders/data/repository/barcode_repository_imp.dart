import 'package:bokrah_retail/app/features/barcoders/data/services/barcodes_service.dart';
import 'package:bokrah_retail/app/features/barcoders/domain/entities/barcode_entity.dart';
import 'package:bokrah_retail/app/features/barcoders/domain/repository/barcode_repository.dart';

class BarcodeRepositoryImpl implements BarcodeRepository {
  final BarcodesService _service;

  BarcodeRepositoryImpl({BarcodesService? service})
    : _service = service ?? BarcodesService();

  @override
  Future<List<BarcodeEntity>> getAllBarcodes() => _service.getAllBarcodes();

  @override
  Future<bool> saveBarcode(BarcodeEntity barcode) =>
      _service.saveBarcode(barcode);

  @override
  Future<bool> updateBarcode(BarcodeEntity barcode) =>
      _service.updateBarcode(barcode);

  @override
  Future<bool> deleteBarcode(int id) => _service.deleteBarcode(id);

  @override
  Future<List<BarcodeItemLink>> getAllLinks() => _service.getAllLinks();

  @override
  Future<void> linkItemToBarcode(int itemId, int barcodeId) =>
      _service.linkItemToBarcode(itemId, barcodeId);

  @override
  Future<void> unlinkItemFromBarcode(int itemId, int barcodeId) =>
      _service.unlinkItemFromBarcode(itemId, barcodeId);

  @override
  Future<List<int>> getItemIdsByBarcode(int barcodeId) =>
      _service.getItemIdsByBarcode(barcodeId);

  @override
  Future<List<int>> getBarcodeIdsByItem(int itemId) =>
      _service.getBarcodeIdsByItem(itemId);

  @override
  Future<void> syncBarcodesForItem(int itemId, Set<int> barcodeIds) =>
      _service.syncBarcodesForItem(itemId, barcodeIds);

  @override
  Future<void> unlinkAllBarcodesForItem(int itemId) =>
      _service.unlinkAllBarcodesForItem(itemId);
}
