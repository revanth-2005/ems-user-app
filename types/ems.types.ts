/**
 * EventSphere Global TypeScript Types & Interfaces
 * Standardized across backend API contracts and frontend clients.
 */

// ── API Response Envelopes ──────────────────────────────────────────────────

export interface ApiResponse<T> {
  success: boolean;
  message?: string;
  data: T;
  error?: {
    code: string;
    message: string;
    details?: unknown;
  };
  timestamp: string;
}

export interface PaginationMeta {
  page: number;
  limit: number;
  totalCount: number;
  totalPages: number;
  hasNextPage: boolean;
  hasPreviousPage: boolean;
}

export interface PaginatedResponse<T> {
  items: T[];
  pagination: PaginationMeta;
}

// ── Auth & User Domain ──────────────────────────────────────────────────────

export type KycStatus = 'PENDING' | 'UNDER_REVIEW' | 'APPROVED' | 'REJECTED';
export type ActivePortal = 'CUSTOMER' | 'ORGANIZER' | 'HOST';

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresIn?: number;
  tokenType?: string; // 'Bearer'
}

export interface User {
  id: string;
  email: string;
  name: string;
  phone?: string;
  city?: string;
  avatarUrl?: string;
  isOrganizer: boolean;
  canHostEvents: boolean;
  kycStatus: KycStatus;
  activePortal: ActivePortal;
  createdAt: string;
  updatedAt: string;
}

export interface Address {
  id: string;
  userId: string;
  addressLine1: string;
  addressLine2?: string;
  landmark?: string;
  city: string;
  state: string;
  pincode: string;
  latitude?: number;
  longitude?: number;
  isDefault: boolean;
}

// ── Master & Catalog Domain ─────────────────────────────────────────────────

export interface Category {
  id: string;
  name: string;
  slug: string;
  iconName?: string;
  description?: string;
  subCategories?: SubCategory[];
}

export interface SubCategory {
  id: string;
  categoryId: string;
  name: string;
  slug: string;
  description?: string;
}

export interface CancellationPolicy {
  id: string;
  title: string;
  description: string;
  refundablePercentage: number;
  cutoffHoursBeforeEvent: number;
}

export interface OrganizerProfile {
  id: string;
  userId: string;
  businessName: string;
  businessType: string;
  city: string;
  description?: string;
  rating: number;
  reviewCount: number;
  totalBookings: number;
  activeListingsCount: number;
  isKycApproved: boolean;
  avatarUrl?: string;
  coverImageUrl?: string;
}

export interface Service {
  id: string;
  organizerProfileId: string;
  organizer: OrganizerProfile;
  name: string;
  slug: string;
  categoryId: string;
  description?: string;
  priceInPaise: number; // Integer (e.g. ₹15,000 = 1500000)
  depositRequiredPaise: number;
  unit: 'FLAT' | 'PER_HOUR' | 'PER_DAY' | 'PER_EVENT';
  leadTimeDays?: number;
  coverImageUrl?: string;
  galleryImages: string[];
  inclusions: string[];
  cancellationPolicy?: CancellationPolicy;
  isActive: boolean;
}

export interface AvailabilitySlot {
  date: string; // ISO YYYY-MM-DD
  isBlocked: boolean;
  reason?: string;
  availableStartTime?: string; // HH:mm
  availableEndTime?: string; // HH:mm
}

export interface OrganizerAvailabilityResponse {
  organizerProfileId: string;
  leadTimeDays: number;
  blockedDates: string[]; // List of YYYY-MM-DD
  slots: AvailabilitySlot[];
}

export interface Package {
  id: string;
  organizerProfileId: string;
  organizer: OrganizerProfile;
  name: string;
  slug: string;
  categoryId: string;
  description?: string;
  priceInPaise: number;
  advanceDepositFlatPaise: number;
  capacityMin: number;
  capacityMax: number;
  coverImageUrl?: string;
  galleryImages: string[];
  lineItems: string[];
  cancellationPolicy?: CancellationPolicy;
  isActive: boolean;
}

export type PricingUnit = 'FIXED' | 'PER_HEAD' | 'PER_HOUR' | 'PER_DAY' | 'PER_EVENT';
export type CatalogSortBy = 'createdAt_desc' | 'price_asc' | 'price_desc' | 'rating_desc';

export interface ServiceQueryParams {
  search?: string;
  categoryId?: string;
  subCategoryId?: string;
  city?: string;
  pricingUnit?: PricingUnit;
  minPrice?: number; // In Paise
  maxPrice?: number; // In Paise
  sortBy?: CatalogSortBy;
  page?: number;
  limit?: number;
}

export interface PackageQueryParams {
  search?: string;
  categoryId?: string;
  city?: string;
  minPrice?: number;
  maxPrice?: number;
  capacity?: number;
  sortBy?: CatalogSortBy;
  page?: number;
  limit?: number;
}

export interface OrganizerQueryParams {
  search?: string;
  city?: string;
  page?: number;
  limit?: number;
}

// ── Cart & Booking Domain ───────────────────────────────────────────────────

export interface CartItem {
  id: string;
  packageId?: string;
  serviceId?: string;
  itemName: string;
  coverImageUrl?: string;
  eventDate: string; // ISO-8601 YYYY-MM-DD
  startTime?: string; // HH:mm
  endTime?: string; // HH:mm
  quantity: number;
  priceInPaise: number;
  depositRequiredPaise: number;
  balanceDuePaise: number;
  organizer: OrganizerProfile;
  cancellationPolicy?: CancellationPolicy;
}

export interface AddCartItemPayload {
  serviceId?: string;
  packageId?: string;
  eventDate: string; // YYYY-MM-DD
  startTime?: string; // HH:mm
  endTime?: string; // HH:mm
  quantity?: number;
}

export interface UpdateCartItemPayload {
  eventDate?: string;
  startTime?: string;
  endTime?: string;
  quantity?: number;
}

export interface Cart {
  items: CartItem[];
  appliedCoupon?: string;
  discountPaise: number;
  subtotalPaise: number;
  totalDepositPaise: number;
  remainingBalanceDuePaise: number;
  finalPayablePaise: number;
}

export type BookingStatus =
  | 'REQUESTED'
  | 'ACCEPTED'
  | 'REJECTED'
  | 'RESCHEDULE_PROPOSED'
  | 'CONFIRMED'
  | 'COMPLETED'
  | 'CANCELLED';

export interface Booking {
  id: string;
  orderId: string;
  customerId: string;
  customerName: string;
  customerPhone?: string;
  organizerProfileId: string;
  organizer: OrganizerProfile;
  packageId?: string;
  serviceId?: string;
  title: string;
  eventDate: string; // ISO-8601
  status: BookingStatus;
  proposedDate?: string;
  rescheduleNote?: string;
  slaDeadline: string; // ISO-8601
  agreedPriceInPaise: number;
  depositPaidPaise: number;
  balanceDuePaise: number;
  createdAt: string;
  updatedAt: string;
}

export type PaymentStatus = 'PENDING' | 'SUCCESS' | 'FAILED' | 'REFUNDED';
export type PaymentGateway = 'RAZORPAY' | 'STRIPE' | 'ESCROW_INTERNAL';

export interface Payment {
  id: string;
  orderId: string;
  bookingId?: string;
  amountPaise: number;
  status: PaymentStatus;
  gateway: PaymentGateway;
  transactionRef?: string;
  paidAt?: string;
}

export interface Order {
  id: string;
  orderNumber: string;
  customerId: string;
  items: CartItem[];
  totalAmountPaise: number;
  depositPaidPaise: number;
  balanceDuePaise: number;
  couponDiscountPaise: number;
  payments: Payment[];
  bookings: Booking[];
  createdAt: string;
}

// ── Checkout & Address Payloads ─────────────────────────────────────────────

export interface CreateAddressPayload {
  addressLine1: string;
  addressLine2?: string;
  landmark?: string;
  city: string;
  state: string;
  pincode: string;
  isDefault?: boolean;
}

export interface CheckoutPayload {
  addressId?: string;
  couponCode?: string;
  notes?: string;
}

export interface CheckoutResponse {
  order: Order;
  bookings: Booking[];
  totalDepositDuePaise: number;
}

// ── Payment & Razorpay Interfaces ───────────────────────────────────────────

export interface CreatePaymentOrderPayload {
  paymentType: 'DEPOSIT' | 'FULL' | 'BALANCE';
  amountInPaise: number;
  orderId: string;
  bookingId?: string;
  currency: 'INR';
}

export interface RazorpayOrderResponse {
  gatewayOrderId: string; // Razorpay order_id (e.g. order_EKwxwp9A15jgx2)
  amountInPaise: number;
  currency: string;
  key: string; // Razorpay Key ID
  orderId: string;
}

export interface VerifyPaymentPayload {
  gatewayOrderId: string;
  gatewayPaymentId: string;
  gatewaySignature: string;
}

export interface PaymentVerificationResponse {
  success: boolean;
  status: 'CAPTURED' | 'FAILED';
  paymentId: string;
  orderId: string;
}
