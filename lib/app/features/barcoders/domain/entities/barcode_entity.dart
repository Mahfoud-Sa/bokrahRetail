class BarcodeEntity {
  final int? id;
  final String code;
  final String? label;
  final DateTime createdAt;

  BarcodeEntity({this.id, required this.code, this.label, DateTime? createdAt})
    : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'label': label,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BarcodeEntity.fromMap(Map<String, dynamic> map) {
    return BarcodeEntity(
      id: map['id'],
      code: map['code'],
      label: map['label'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

class BarcodeItemLink {
  final int itemId;
  final int barcodeId;

  BarcodeItemLink({required this.itemId, required this.barcodeId});

  Map<String, dynamic> toMap() => {'itemId': itemId, 'barcodeId': barcodeId};

  factory BarcodeItemLink.fromMap(Map<String, dynamic> map) {
    return BarcodeItemLink(itemId: map['itemId'], barcodeId: map['barcodeId']);
  }
}
