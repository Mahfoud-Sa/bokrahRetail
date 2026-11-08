/**
 * TypeScript Interfaces for Authentication & Registration Endpoints
 * Base Route: /api/auth
 * Content-Type: application/json
 */

/**
 * Phone number item representation
 */
export interface PhoneNumberItem {
  number: string;
  type: string; // e.g., "Mobile"
}

/**
 * Supported registration roles
 */
export type RegistrationRole = 'restaurant' | 'customer' | 'delivery' | 'admin';

/**
 * Request payload for POST /api/auth/register/{role}
 */
export interface UserRegisterRequest {
  name: string;
  birthDate: string; // ISO 8601 string: YYYY-MM-DDTHH:mm:ssZ
  email: string;
  password: string;
  phoneNumber: string;
  address?: string;
  phoneNumbers?: PhoneNumberItem[];
}

/**
 * Response for POST /api/auth/register/{role} (200 OK)
 */
export interface AuthUserResponse {
  id: number;
  name: string;
  email: string;
  isActive: boolean;
  roles: string[];
}

/**
 * Request payload for POST /api/auth/login
 */
export interface LoginRequest {
  email: string;
  password: string;
}

/**
 * Response for POST /api/auth/login (200 OK)
 */
export interface LoginResponse {
  id: number;
  name: string | null;
  email: string;
  isActive: boolean;
  token: string;
  isEmailVerified: boolean;
  isAccountVerified: boolean;
  roles: string[];
}

/**
 * Authenticated user session
 */
export interface UserSession {
  id: number;
  name: string | null;
  email: string;
  roles: string[];
  isEmailVerified: boolean;
  isAccountVerified: boolean;
}

