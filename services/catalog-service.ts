import {
  ApiResponse,
  Category,
  OrganizerProfile,
  OrganizerQueryParams,
  Package,
  PackageQueryParams,
  PaginatedResponse,
  Service,
  ServiceQueryParams,
} from '../types/ems.types';
import { apiClient } from './api-client';

/**
 * Builds a valid query string from a key-value object, filtering out undefined/null/empty keys.
 */
function buildQueryString(params: Record<string, any> = {}): string {
  const query = new URLSearchParams();

  Object.entries(params).forEach(([key, value]) => {
    if (value !== undefined && value !== null && value !== '') {
      query.append(key, String(value));
    }
  });

  const str = query.toString();
  return str ? `?${str}` : '';
}

/**
 * Catalog Service handling Master categories, Services, Packages, and Organizers directory.
 */
export class CatalogService {
  /**
   * Fetch Master Categories
   * GET /master/categories
   */
  async getCategories(): Promise<Category[]> {
    const res = await apiClient.get<Category[]>('/api/v1/master/categories');
    return res.data || [];
  }

  /**
   * Fetch Standalone Services with filtering & pagination
   * GET /catalog/services
   */
  async getServices(
    params: ServiceQueryParams = {}
  ): Promise<PaginatedResponse<Service> | Service[]> {
    const qs = buildQueryString(params);
    const res = await apiClient.get<PaginatedResponse<Service> | Service[]>(
      `/api/v1/catalog/services${qs}`
    );
    return res.data;
  }

  /**
   * Fetch Service by ID
   * GET /catalog/services/:id
   */
  async getServiceById(id: string): Promise<Service> {
    const res = await apiClient.get<Service>(`/api/v1/catalog/services/${id}`);
    return res.data;
  }

  /**
   * Fetch Bundled Event Packages with filtering & pagination
   * GET /catalog/packages
   */
  async getPackages(
    params: PackageQueryParams = {}
  ): Promise<PaginatedResponse<Package> | Package[]> {
    const qs = buildQueryString(params);
    const res = await apiClient.get<PaginatedResponse<Package> | Package[]>(
      `/api/v1/catalog/packages${qs}`
    );
    return res.data;
  }

  /**
   * Fetch Package by ID
   * GET /catalog/packages/:id
   */
  async getPackageById(id: string): Promise<Package> {
    const res = await apiClient.get<Package>(`/api/v1/catalog/packages/${id}`);
    return res.data;
  }

  /**
   * Fetch Verified Organizers Directory
   * GET /catalog/organizers
   */
  async getOrganizers(
    params: OrganizerQueryParams = {}
  ): Promise<PaginatedResponse<OrganizerProfile> | OrganizerProfile[]> {
    const qs = buildQueryString(params);
    const res = await apiClient.get<
      PaginatedResponse<OrganizerProfile> | OrganizerProfile[]
    >(`/api/v1/catalog/organizers${qs}`);
    return res.data;
  }

  /**
   * Fetch Organizer Profile by ID
   * GET /catalog/organizers/:id
   */
  async getOrganizerById(id: string): Promise<OrganizerProfile> {
    const res = await apiClient.get<OrganizerProfile>(
      `/api/v1/catalog/organizers/${id}`
    );
    return res.data;
  }

  /**
   * Fetch Organizer Blocked Dates & Availability Slots
   * GET /catalog/organizers/:id/availability?startDate=...&endDate=...
   */
  async getOrganizerAvailability(
    organizerId: string,
    startDate?: string,
    endDate?: string
  ): Promise<any> {
    const qs = buildQueryString({ startDate, endDate });
    const res = await apiClient.get<any>(
      `/api/v1/catalog/organizers/${organizerId}/availability${qs}`
    );
    return res.data;
  }
}

export const catalogService = new CatalogService();
