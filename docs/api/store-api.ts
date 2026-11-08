/**
 * ASP.NET Core Store Management API Client & Contracts
 * Base URL: /api/stores
 * Content-Type: application/json
 * Auth: Bearer <JWT_TOKEN>
 */

import axios, { AxiosInstance } from 'axios';

// ----------------------------------------------------
// 1. TypeScript Types & Interfaces
// ----------------------------------------------------

export interface CreateStoreRequest {
  name: string;             // Required, 2-120 chars
  description?: string;      // Optional, max 500 chars
  phoneNumber?: string;      // Optional, valid phone, max 30 chars
  email?: string;            // Optional, valid email, max 256 chars
  address?: string;          // Optional, max 500 chars
  currencyCode?: string;     // Optional, default "JOD", 3-10 chars
  isActive?: boolean;        // Optional, default true
}

export interface StoreResponse {
  id: number;
  ownerUserId: number;
  name: string;
  description: string | null;
  phoneNumber: string | null;
  email: string | null;
  address: string | null;
  currencyCode: string;
  isActive: boolean;
  createdAtUtc: string;      // ISO 8601 string
  updatedAtUtc: string | null;
  currentUserRole: 'Owner' | 'Manager' | 'Staff' | null;
}

export interface ApiErrorResponse {
  message?: string;
  errors?: Record<string, string[]>;
}

// ----------------------------------------------------
// 2. API Client Setup (Axios / Fetch)
// ----------------------------------------------------

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || 'https://localhost:7189/api';

export const apiClient: AxiosInstance = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Attach JWT token from auth storage (never send ownerUserId in body)
apiClient.interceptors.request.use((config) => {
  if (typeof window !== 'undefined') {
    const token = localStorage.getItem('token') || localStorage.getItem('access_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
  }
  return config;
});

// ----------------------------------------------------
// 3. Store API Endpoints Implementation
// ----------------------------------------------------

export const StoreApi = {
  /**
   * POST /api/stores
   * Creates a new tenant store and sets the current user as Owner.
   */
  createStore: async (payload: CreateStoreRequest): Promise<StoreResponse> => {
    // Client-side pre-validations matching ASP.NET Core spec
    if (!payload.name || payload.name.trim().length < 2 || payload.name.trim().length > 120) {
      throw new Error('Store name is required and must be between 2 and 120 characters.');
    }
    if (payload.currencyCode && (payload.currencyCode.length < 3 || payload.currencyCode.length > 10)) {
      throw new Error('Currency code must be between 3 and 10 characters.');
    }

    const response = await apiClient.post<StoreResponse>('/stores', {
      ...payload,
      currencyCode: payload.currencyCode || 'JOD',
      isActive: payload.isActive ?? true,
    });
    return response.data;
  },

  /**
   * GET /api/stores
   * Retrieves all active stores where the authenticated user is Owner, Manager, or Staff.
   */
  getMyStores: async (): Promise<StoreResponse[]> => {
    const response = await apiClient.get<StoreResponse[]>('/stores');
    return response.data;
  },

  /**
   * GET /api/stores/{storeId}
   * Retrieves details for a specific store. Restricted to Owner or Manager.
   */
  getStoreById: async (storeId: number): Promise<StoreResponse> => {
    const response = await apiClient.get<StoreResponse>(`/stores/${storeId}`);
    return response.data;
  },
};

// ----------------------------------------------------
// 4. Role Guards Helper
// ----------------------------------------------------

export const StoreRoleGuards = {
  isOwner: (store: StoreResponse) => store.currentUserRole === 'Owner',
  isManager: (store: StoreResponse) => store.currentUserRole === 'Manager',
  isStaff: (store: StoreResponse) => store.currentUserRole === 'Staff',
  canManageSettings: (store: StoreResponse) => store.currentUserRole === 'Owner',
  isReadOnlySettings: (store: StoreResponse) => store.currentUserRole === 'Manager',
};

