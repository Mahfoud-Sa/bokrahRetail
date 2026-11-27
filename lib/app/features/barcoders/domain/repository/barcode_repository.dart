import 'package:bokrah_retail/app/features/barcoders/domain/entities/barcode_entity.dart';

abstract class BarcodeRepository {
  Future<List<BarcodeEntity>> getAllBarcodes();
  Future<bool> saveBarcode(BarcodeEntity barcode);
  Future<bool> updateBarcode(BarcodeEntity barcode);
  Future<bool> deleteBarcode(int id);
  Future<List<BarcodeItemLink>> getAllLinks();
  Future<void> linkItemToBarcode(int itemId, int barcodeId);
  Future<void> unlinkItemFromBarcode(int itemId, int barcodeId);
  Future<List<int>> getItemIdsByBarcode(int barcodeId);
  Future<List<int>> getBarcodeIdsByItem(int itemId);
  Future<void> syncBarcodesForItem(int itemId, Set<int> barcodeIds);
  Future<void> unlinkAllBarcodesForItem(int itemId);
}
