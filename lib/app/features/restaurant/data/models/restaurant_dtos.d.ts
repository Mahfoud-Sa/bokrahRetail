/**
 * Restaurant DTO Interfaces for Create / Add Restaurant Feature
 * Endpoint: POST /api/restaurants
 */

export interface RestaurantPhoneNumberInput {
  number: string;
  type?: string; // e.g., 'Mobile' | 'Landline' | 'WhatsApp' | 'Primary'
}

export interface CreateRestaurantRequest {
  name?: string;                 // Fallback/main name
  nameAr?: string;               // Arabic name (e.g., "مطعم السعادة")
  nameEn?: string;               // English name (e.g., "Al-Saada Restaurant")
  slogan?: string;               // Catchy slogan / tagline
  subtitle?: string;             // Subtitle / category (e.g., "Authentic Italian Pizza")
  description?: string;          // Full description / about the restaurant
  address?: string;              // Physical address
  googleMapsUrl?: string;        // Google Maps location URL
  latitude?: number | null;      // Latitude coordinate
  longitude?: number | null;     // Longitude coordinate
  websiteUrl?: string;           // Official website URL
  phone?: string;                // Primary contact number
  phoneNumbers?: RestaurantPhoneNumberInput[]; // List of phone numbers
}

export interface RestaurantPhoneNumberResponse {
  id: number;
  number: string;
  type?: string;
}

export interface RestaurantResponse {
  id: number;
  name: string;
  nameAr?: string;
  nameEn?: string;
  slogan?: string;
  subtitle?: string;
  description?: string;
  address?: string;
  googleMapsUrl?: string;
  latitude?: number;
  longitude?: number;
  websiteUrl?: string;
  phone?: string;
  userId?: number;
  ownerName?: string;
  phoneNumbers: Array<RestaurantPhoneNumberResponse>;
}
