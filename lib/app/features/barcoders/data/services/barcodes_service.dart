import 'dart:convert';
import 'package:bokrah_retail/app/features/barcoders/domain/entities/barcode_entity.dart';
import 'package:bokrah_retail/app/features/sync/data/services/sync_outbox_recorder.dart';
import 'package:bokrah_retail/app/features/sync/domain/entities/sync_operation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BarcodesService {
  static const String _barcodesKey = 'barcodes_list';
  static const String _linksKey = 'barcode_item_links';
  final SyncOutboxRecorder _outboxRecorder;

  BarcodesService({SyncOutboxRecorder? outboxRecorder})
      : _outboxRecorder = outboxRecorder ?? SyncOutboxRecorder();

  Future<List<BarcodeEntity>> getAllBarcodes() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_barcodesKey) ?? [];
    return list.map((e) => BarcodeEntity.fromMap(json.decode(e))).toList();
  }

  Future<bool> saveBarcode(BarcodeEntity barcode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await getAllBarcodes();
      final newBarcode = BarcodeEntity(
        id: barcode.id ?? DateTime.now().millisecondsSinceEpoch,
        code: barcode.code,
        label: barcode.label,
        createdAt: barcode.createdAt,
      );
      list.add(newBarcode);
      await prefs.setStringList(
        _barcodesKey,
        list.map((e) => json.encode(e.toMap())).toList(),
      );
      if (newBarcode.id != null) {
        await _outboxRecorder.record(
          entityType: SyncEntityType.barcode,
          operationType: SyncOperationType.create,
          localEntityId: newBarcode.id!,
          payload: newBarcode.toMap(),
        );
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateBarcode(BarcodeEntity barcode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await getAllBarcodes();
      final index = list.indexWhere((e) => e.id == barcode.id);
      if (index != -1) {
        list[index] = barcode;
        await prefs.setStringList(
          _barcodesKey,
          list.map((e) => json.encode(e.toMap())).toList(),
        );
        if (barcode.id != null) {
          await _outboxRecorder.record(
            entityType: SyncEntityType.barcode,
            operationType: SyncOperationType.update,
            localEntityId: barcode.id!,
            payload: barcode.toMap(),
          );
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteBarcode(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await getAllBarcodes();
      list.removeWhere((e) => e.id == id);
      await prefs.setStringList(
        _barcodesKey,
        list.map((e) => json.encode(e.toMap())).toList(),
      );

      // Also remove links
      final links = await getAllLinks();
      links.removeWhere((link) => link.barcodeId == id);
      await _saveLinks(links);

      await _outboxRecorder.record(
        entityType: SyncEntityType.barcode,
        operationType: SyncOperationType.delete,
        localEntityId: id,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  // Many-to-Many Linking
  Future<List<BarcodeItemLink>> getAllLinks() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_linksKey) ?? [];
    return list.map((e) => BarcodeItemLink.fromMap(json.decode(e))).toList();
  }

  Future<void> _saveLinks(List<BarcodeItemLink> links) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _linksKey,
      links.map((e) => json.encode(e.toMap())).toList(),
    );
  }

  Future<void> linkItemToBarcode(int itemId, int barcodeId) async {
    final links = await getAllLinks();
    if (!links.any((l) => l.itemId == itemId && l.barcodeId == barcodeId)) {
      final link = BarcodeItemLink(itemId: itemId, barcodeId: barcodeId);
      links.add(link);
      await _saveLinks(links);
      await _outboxRecorder.record(
        entityType: SyncEntityType.barcodeLink,
        operationType: SyncOperationType.create,
        localEntityId: itemId * 1000000 + barcodeId,
        payload: link.toMap(),
      );
    }
  }

  Future<void> unlinkItemFromBarcode(int itemId, int barcodeId) async {
    final links = await getAllLinks();
    links.removeWhere((l) => l.itemId == itemId && l.barcodeId == barcodeId);
    await _saveLinks(links);
    await _outboxRecorder.record(
      entityType: SyncEntityType.barcodeLink,
      operationType: SyncOperationType.delete,
      localEntityId: itemId * 1000000 + barcodeId,
      payload: {'itemId': itemId, 'barcodeId': barcodeId},
    );
  }

  Future<List<int>> getItemIdsByBarcode(int barcodeId) async {
    final links = await getAllLinks();
    return links
        .where((l) => l.barcodeId == barcodeId)
        .map((l) => l.itemId)
        .toList();
  }

  Future<List<int>> getBarcodeIdsByItem(int itemId) async {
    final links = await getAllLinks();
    return links
        .where((l) => l.itemId == itemId)
        .map((l) => l.barcodeId)
        .toList();
  }
}
