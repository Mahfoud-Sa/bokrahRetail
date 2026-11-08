import 'package:flutter_test/flutter_test.dart';
import 'package:bokrah_retail/app/features/restaurant/data/models/restaurant_dto.dart';

void main() {
  group('Restaurant DTOs Tests', () {
    test('RestaurantPhoneNumberInput serializes and deserializes correctly', () {
      const input = RestaurantPhoneNumberInput(
        number: '+966501234567',
        type: 'Mobile',
      );

      final json = input.toJson();
      expect(json['number'], equals('+966501234567'));
      expect(json['type'], equals('Mobile'));

      final parsed = RestaurantPhoneNumberInput.fromJson(json);
      expect(parsed.number, equals('+966501234567'));
      expect(parsed.type, equals('Mobile'));
      expect(parsed, equals(input));
    });

    test('CreateRestaurantRequest hasValidName rule enforces at least one name', () {
      expect(const CreateRestaurantRequest().hasValidName, isFalse);
      expect(const CreateRestaurantRequest(name: '   ').hasValidName, isFalse);
      expect(const CreateRestaurantRequest(nameAr: 'مطعم السعادة').hasValidName, isTrue);
      expect(const CreateRestaurantRequest(nameEn: 'Al-Saada Restaurant').hasValidName, isTrue);
      expect(const CreateRestaurantRequest(name: 'Al-Saada Restaurant').hasValidName, isTrue);
    });

    test('CreateRestaurantRequest serializes full payload matching spec', () {
      const request = CreateRestaurantRequest(
        name: 'Al-Saada Restaurant',
        nameAr: 'مطعم السعادة',
        nameEn: 'Al-Saada Restaurant',
        slogan: 'The Real Taste of Joy',
        subtitle: 'Traditional & Modern Cuisine',
        description: 'Family-friendly restaurant offering high-quality dishes.',
        address: 'King Fahd Road, Riyadh, Saudi Arabia',
        googleMapsUrl: 'https://maps.google.com/?q=24.7136,46.6753',
        latitude: 24.7136,
        longitude: 46.6753,
        websiteUrl: 'https://alsaada-restaurant.com',
        phone: '+966501234567',
        phoneNumbers: [
          RestaurantPhoneNumberInput(number: '+966501234567', type: 'Mobile'),
          RestaurantPhoneNumberInput(number: '+966112345678', type: 'Landline'),
          RestaurantPhoneNumberInput(number: '+966509876543', type: 'WhatsApp'),
        ],
      );

      final json = request.toJson();
      expect(json['name'], equals('Al-Saada Restaurant'));
      expect(json['nameAr'], equals('مطعم السعادة'));
      expect(json['nameEn'], equals('Al-Saada Restaurant'));
      expect(json['slogan'], equals('The Real Taste of Joy'));
      expect(json['subtitle'], equals('Traditional & Modern Cuisine'));
      expect(json['description'], equals('Family-friendly restaurant offering high-quality dishes.'));
      expect(json['address'], equals('King Fahd Road, Riyadh, Saudi Arabia'));
      expect(json['googleMapsUrl'], equals('https://maps.google.com/?q=24.7136,46.6753'));
      expect(json['latitude'], equals(24.7136));
      expect(json['longitude'], equals(46.6753));
      expect(json['websiteUrl'], equals('https://alsaada-restaurant.com'));
      expect(json['phone'], equals('+966501234567'));
      expect((json['phoneNumbers'] as List).length, equals(3));
    });

    test('RestaurantResponse parses 201 Created payload and converts to RestaurantEntity', () {
      final sampleJson = {
        "id": 12,
        "name": "Al-Saada Restaurant",
        "nameAr": "مطعم السعادة",
        "nameEn": "Al-Saada Restaurant",
        "slogan": "The Real Taste of Joy",
        "subtitle": "Traditional & Modern Cuisine",
        "description": "Family-friendly restaurant offering high-quality dishes.",
        "address": "King Fahd Road, Riyadh, Saudi Arabia",
        "googleMapsUrl": "https://maps.google.com/?q=24.7136,46.6753",
        "latitude": 24.7136,
        "longitude": 46.6753,
        "websiteUrl": "https://alsaada-restaurant.com",
        "phone": "+966501234567",
        "userId": 45,
        "ownerName": "Ahmed Ali",
        "phoneNumbers": [
          {
            "id": 101,
            "number": "+966501234567",
            "type": "Mobile"
          },
          {
            "id": 102,
            "number": "+966112345678",
            "type": "Landline"
          },
          {
            "id": 103,
            "number": "+966509876543",
            "type": "WhatsApp"
          }
        ]
      };

      final response = RestaurantResponse.fromJson(sampleJson);
      expect(response.id, equals(12));
      expect(response.name, equals('Al-Saada Restaurant'));
      expect(response.nameAr, equals('مطعم السعادة'));
      expect(response.nameEn, equals('Al-Saada Restaurant'));
      expect(response.userId, equals(45));
      expect(response.ownerName, equals('Ahmed Ali'));
      expect(response.phoneNumbers.length, equals(3));
      expect(response.phoneNumbers[0].id, equals(101));
      expect(response.phoneNumbers[0].type, equals('Mobile'));

      final entity = response.toEntity();
      expect(entity.id, equals('12'));
      expect(entity.nameAr, equals('مطعم السعادة'));
      expect(entity.nameEn, equals('Al-Saada Restaurant'));
      expect(entity.slogan, equals('The Real Taste of Joy'));
      expect(entity.cuisineType, equals('Traditional & Modern Cuisine'));
      expect(entity.phoneNumber, equals('+966501234567'));
      expect(entity.mobileNumber, equals('+966501234567'));
      expect(entity.street, equals('King Fahd Road, Riyadh, Saudi Arabia'));
      expect(entity.website, equals('https://alsaada-restaurant.com'));
    });
  });
}
