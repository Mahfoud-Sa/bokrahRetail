import 'package:equatable/equatable.dart';

/// Represents a phone number entry for a store / shop.
class StorePhoneNumberInput extends Equatable {
  final int? id;
  final String number;
  final String type; // e.g., 'Mobile', 'Landline', 'WhatsApp', 'Sales', 'Support'

  const StorePhoneNumberInput({
    this.id,
    required this.number,
    this.type = 'Mobile',
  });

  factory StorePhoneNumberInput.fromJson(Map<String, dynamic> json) {
    return StorePhoneNumberInput(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? ''),
      number: json['number']?.toString() ?? '',
      type: json['type']?.toString() ?? 'Mobile',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'number': number,
      'type': type,
    };
  }

  StorePhoneNumberInput copyWith({
    int? id,
    String? number,
    String? type,
  }) {
    return StorePhoneNumberInput(
      id: id ?? this.id,
      number: number ?? this.number,
      type: type ?? this.type,
    );
  }

  @override
  List<Object?> get props => [id, number, type];
}

/// Backward compatibility alias
typedef RestaurantPhoneNumberInput = StorePhoneNumberInput;
