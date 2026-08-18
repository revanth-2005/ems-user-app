import {
  AddCartItemPayload,
  ApiResponse,
  Cart,
  UpdateCartItemPayload,
} from '../types/ems.types';
import { apiClient } from './api-client';

/**
 * Cart Service handling multi-vendor shopping cart operations.
 */
export class CartService {
  /**
   * Fetch current user Cart
   * GET /cart
   */
  async getCart(): Promise<Cart> {
    const res = await apiClient.get<Cart>('/api/v1/cart');
    return (
      res.data || {
        items: [],
        discountPaise: 0,
        subtotalPaise: 0,
        totalDepositPaise: 0,
        remainingBalanceDuePaise: 0,
        finalPayablePaise: 0,
      }
    );
  }

  /**
   * Add Item (Service or Package) to Cart
   * POST /cart/items
   */
  async addItem(payload: AddCartItemPayload): Promise<Cart> {
    const res = await apiClient.post<Cart>('/api/v1/cart/items', payload);
    return res.data;
  }

  /**
   * Update scheduled date, times, or quantity of a cart item
   * PUT /cart/items/:id
   */
  async updateItem(
    itemId: string,
    payload: UpdateCartItemPayload
  ): Promise<Cart> {
    const res = await apiClient.put<Cart>(
      `/api/v1/cart/items/${itemId}`,
      payload
    );
    return res.data;
  }

  /**
   * Remove single item from Cart
   * DELETE /cart/items/:id
   */
  async removeItem(itemId: string): Promise<Cart> {
    const res = await apiClient.delete<Cart>(`/api/v1/cart/items/${itemId}`);
    return res.data;
  }

  /**
   * Clear all items in Cart
   * DELETE /cart
   */
  async clearCart(): Promise<void> {
    await apiClient.delete('/api/v1/cart');
  }
}

export const cartService = new CartService();
