import {
  AddCartItemPayload,
  Cart,
  CartItem,
  UpdateCartItemPayload,
} from '../types/ems.types';
import { cartService } from '../services/cart-service';

export interface CartStoreState extends Cart {
  isLoading: boolean;
  error: string | null;
}

export type CartStoreListener = (state: CartStoreState) => void;

/**
 * Calculates cart pricing totals from items and applied coupon discount.
 */
export function calculateCartTotals(
  items: CartItem[],
  discountPaise = 0
): {
  subtotalPaise: number;
  totalDepositPaise: number;
  remainingBalanceDuePaise: number;
  finalPayablePaise: number;
} {
  const subtotal = items.reduce(
    (sum, item) => sum + (item.priceInPaise || 0) * (item.quantity || 1),
    0
  );

  const totalDeposit = items.reduce(
    (sum, item) =>
      sum + (item.depositRequiredPaise || 0) * (item.quantity || 1),
    0
  );

  const remainingBalance = Math.max(0, subtotal - totalDeposit);
  const finalPayable = Math.max(0, totalDeposit - discountPaise);

  return {
    subtotalPaise: subtotal,
    totalDepositPaise: totalDeposit,
    remainingBalanceDuePaise: remainingBalance,
    finalPayablePaise: finalPayable,
  };
}

/**
 * Global Multi-Vendor Cart Store
 * Supports optimistic UI mutations and automatic total recalculations.
 */
export class CartStore {
  private state: CartStoreState = {
    items: [],
    discountPaise: 0,
    subtotalPaise: 0,
    totalDepositPaise: 0,
    remainingBalanceDuePaise: 0,
    finalPayablePaise: 0,
    isLoading: false,
    error: null,
  };

  private listeners: Set<CartStoreListener> = new Set();

  constructor() {
    this.fetchCart();
  }

  public getState(): CartStoreState {
    return { ...this.state };
  }

  public getItemCount(): number {
    return this.state.items.reduce((count, item) => count + (item.quantity || 1), 0);
  }

  public subscribe(listener: CartStoreListener): () => void {
    this.listeners.add(listener);
    listener(this.getState());
    return () => this.listeners.delete(listener);
  }

  private notify(): void {
    const currentState = this.getState();
    this.listeners.forEach((listener) => listener(currentState));
  }

  private setState(partial: Partial<CartStoreState>): void {
    this.state = { ...this.state, ...partial };
    this.notify();
  }

  /**
   * 1. Fetch Cart from Backend
   */
  async fetchCart(): Promise<void> {
    this.setState({ isLoading: true, error: null });
    try {
      const cart = await cartService.getCart();
      const totals = calculateCartTotals(cart.items, cart.discountPaise || 0);

      this.setState({
        items: cart.items,
        appliedCoupon: cart.appliedCoupon,
        discountPaise: cart.discountPaise || 0,
        ...totals,
        isLoading: false,
      });
    } catch (err: any) {
      this.setState({
        isLoading: false,
        error: err.message || 'Failed to load cart',
      });
    }
  }

  /**
   * 2. Add Item to Cart
   */
  async addItem(payload: AddCartItemPayload): Promise<void> {
    this.setState({ isLoading: true, error: null });
    try {
      const updatedCart = await cartService.addItem(payload);
      const totals = calculateCartTotals(
        updatedCart.items,
        updatedCart.discountPaise || 0
      );

      this.setState({
        items: updatedCart.items,
        appliedCoupon: updatedCart.appliedCoupon,
        discountPaise: updatedCart.discountPaise || 0,
        ...totals,
        isLoading: false,
      });
    } catch (err: any) {
      this.setState({
        isLoading: false,
        error: err.message || 'Failed to add item to cart',
      });
      throw err;
    }
  }

  /**
   * 3. Update Cart Item with Optimistic Update & Rollback
   */
  async updateItem(
    itemId: string,
    payload: UpdateCartItemPayload
  ): Promise<void> {
    const previousState = this.getState();

    // Optimistic Update
    const optimisticItems = this.state.items.map((item) => {
      if (item.id === itemId) {
        return {
          ...item,
          ...payload,
          quantity: payload.quantity ?? item.quantity,
        };
      }
      return item;
    });

    const optimisticTotals = calculateCartTotals(
      optimisticItems,
      this.state.discountPaise
    );

    this.setState({
      items: optimisticItems,
      ...optimisticTotals,
    });

    try {
      const serverCart = await cartService.updateItem(itemId, payload);
      const totals = calculateCartTotals(
        serverCart.items,
        serverCart.discountPaise || 0
      );

      this.setState({
        items: serverCart.items,
        appliedCoupon: serverCart.appliedCoupon,
        discountPaise: serverCart.discountPaise || 0,
        ...totals,
      });
    } catch (err: any) {
      // Rollback on network failure
      this.setState({
        items: previousState.items,
        subtotalPaise: previousState.subtotalPaise,
        totalDepositPaise: previousState.totalDepositPaise,
        remainingBalanceDuePaise: previousState.remainingBalanceDuePaise,
        finalPayablePaise: previousState.finalPayablePaise,
        error: 'Failed to update item, rolled back changes.',
      });
      throw err;
    }
  }

  /**
   * 4. Remove Single Item with Optimistic Update & Rollback
   */
  async removeItem(itemId: string): Promise<void> {
    const previousState = this.getState();

    // Optimistic item filter
    const remainingItems = this.state.items.filter((item) => item.id !== itemId);
    const totals = calculateCartTotals(remainingItems, this.state.discountPaise);

    this.setState({
      items: remainingItems,
      ...totals,
    });

    try {
      const serverCart = await cartService.removeItem(itemId);
      const updatedTotals = calculateCartTotals(
        serverCart.items,
        serverCart.discountPaise || 0
      );

      this.setState({
        items: serverCart.items,
        appliedCoupon: serverCart.appliedCoupon,
        discountPaise: serverCart.discountPaise || 0,
        ...updatedTotals,
      });
    } catch (err: any) {
      // Rollback
      this.setState({
        items: previousState.items,
        subtotalPaise: previousState.subtotalPaise,
        totalDepositPaise: previousState.totalDepositPaise,
        remainingBalanceDuePaise: previousState.remainingBalanceDuePaise,
        finalPayablePaise: previousState.finalPayablePaise,
        error: 'Failed to remove item.',
      });
      throw err;
    }
  }

  /**
   * 5. Clear Entire Cart
   */
  async clearCart(): Promise<void> {
    const previousItems = [...this.state.items];
    this.setState({
      items: [],
      subtotalPaise: 0,
      totalDepositPaise: 0,
      remainingBalanceDuePaise: 0,
      finalPayablePaise: 0,
    });

    try {
      await cartService.clearCart();
    } catch (err: any) {
      this.setState({
        items: previousItems,
        ...calculateCartTotals(previousItems, this.state.discountPaise),
        error: 'Failed to clear cart.',
      });
      throw err;
    }
  }
}

// Global Singleton Export
export const cartStore = new CartStore();
