import {
  CreatePaymentOrderPayload,
  PaymentVerificationResponse,
  RazorpayOrderResponse,
  VerifyPaymentPayload,
} from '../types/ems.types';
import { apiClient, ApiError } from './api-client';

export interface RazorpayModalPrefill {
  name?: string;
  email?: string;
  contact?: string;
}

export interface LaunchRazorpayOptions {
  key: string;
  gatewayOrderId: string;
  amountInPaise: number;
  currency?: string;
  name?: string;
  description?: string;
  prefill?: RazorpayModalPrefill;
  themeColor?: string;
}

/**
 * Payment Service handling Razorpay order initialization, SDK checkout, and signature verification.
 */
export class PaymentService {
  /**
   * Step 1: Create Gateway Payment Order on Backend
   * POST /payments/create-order
   */
  async createPaymentOrder(
    payload: CreatePaymentOrderPayload
  ): Promise<RazorpayOrderResponse> {
    const res = await apiClient.post<RazorpayOrderResponse>(
      '/api/v1/payments/create-order',
      payload
    );
    return res.data;
  }

  /**
   * Step 2: Verify Cryptographic Razorpay Signature on Backend
   * POST /payments/verify
   */
  async verifyPayment(
    payload: VerifyPaymentPayload
  ): Promise<PaymentVerificationResponse> {
    const res = await apiClient.post<PaymentVerificationResponse>(
      '/api/v1/payments/verify',
      payload
    );
    return res.data;
  }

  /**
   * Step 3: Launch Razorpay Standard Checkout Modal
   */
  public async launchRazorpayCheckout(
    options: LaunchRazorpayOptions
  ): Promise<VerifyPaymentPayload> {
    return new Promise((resolve, reject) => {
      const windowObj = globalThis as any;

      if (!windowObj?.Razorpay) {
        // Fallback for non-browser or simulated test environments
        if (typeof window === 'undefined') {
          return reject(
            new ApiError(
              'Razorpay SDK is not supported in this environment',
              500,
              'SDK_UNAVAILABLE'
            )
          );
        }

        // Dynamically load Razorpay checkout script if absent
        const script = document.createElement('script');
        script.src = 'https://checkout.razorpay.com/v1/checkout.js';
        script.async = true;
        script.onload = () => {
          this.executeRazorpayModal(options, resolve, reject);
        };
        script.onerror = () => {
          reject(
            new ApiError(
              'Failed to load Razorpay payment gateway SDK',
              500,
              'SCRIPT_LOAD_ERROR'
            )
          );
        };
        document.body.appendChild(script);
        return;
      }

      this.executeRazorpayModal(options, resolve, reject);
    });
  }

  private executeRazorpayModal(
    options: LaunchRazorpayOptions,
    resolve: (val: VerifyPaymentPayload) => void,
    reject: (reason: any) => void
  ): void {
    const windowObj = globalThis as any;

    const rzpOptions = {
      key: options.key,
      amount: options.amountInPaise,
      currency: options.currency || 'INR',
      name: options.name || 'EventSphere Booking Deposit',
      description: options.description || 'Advance Deposit to Freeze Date',
      order_id: options.gatewayOrderId,
      prefill: options.prefill || {},
      theme: {
        color: options.themeColor || '#6C63FF',
      },
      handler: (response: any) => {
        if (
          response.razorpay_order_id &&
          response.razorpay_payment_id &&
          response.razorpay_signature
        ) {
          resolve({
            gatewayOrderId: response.razorpay_order_id,
            gatewayPaymentId: response.razorpay_payment_id,
            gatewaySignature: response.razorpay_signature,
          });
        } else {
          reject(
            new ApiError(
              'Incomplete payment response from gateway',
              400,
              'INVALID_PAYMENT_RESPONSE'
            )
          );
        }
      },
      modal: {
        ondismiss: () => {
          reject(
            new ApiError('Payment cancelled by user', 499, 'PAYMENT_CANCELLED')
          );
        },
      },
    };

    try {
      const rzpInstance = new windowObj.Razorpay(rzpOptions);
      rzpInstance.open();
    } catch (err: any) {
      reject(
        new ApiError(
          err.message || 'Failed to open Razorpay modal',
          500,
          'MODAL_ERROR'
        )
      );
    }
  }

  /**
   * Complete End-to-End Orchestrated Payment Flow
   */
  async executeFullCheckoutPayment(
    orderId: string,
    amountInPaise: number,
    prefill?: RazorpayModalPrefill
  ): Promise<PaymentVerificationResponse> {
    // 1. Create Gateway Order
    const orderData = await this.createPaymentOrder({
      paymentType: 'DEPOSIT',
      amountInPaise,
      orderId,
      currency: 'INR',
    });

    // 2. Launch Razorpay UI Modal
    const paymentResult = await this.launchRazorpayCheckout({
      key: orderData.key,
      gatewayOrderId: orderData.gatewayOrderId,
      amountInPaise: orderData.amountInPaise,
      prefill,
    });

    // 3. Verify Signature
    return await this.verifyPayment(paymentResult);
  }
}

export const paymentService = new PaymentService();
