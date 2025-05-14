import { Injectable } from '@nestjs/common';
import { CartBodyType } from 'src/routes/cart/cart.model';
import { CartRepository } from 'src/routes/cart/cart.repo';

@Injectable()
export class CartService {
  constructor(private readonly cartRepository: CartRepository) {}

  async addToCart(body: CartBodyType, user_id: number) {
    return this.cartRepository.addToCart(body, user_id);
  }

  async getCartOfUser(user_id: number) {
    return this.cartRepository.getCartOfUser(user_id);
  }

  async getCart(user_id: number, restaurantId: string) {
    return this.cartRepository.getCart(user_id, restaurantId);
  }

  async deleteAllItemFromCart(restaurantId: string, user_id: number) {
    return this.cartRepository.deleteAllItemFromCart(restaurantId, user_id);
  }

  async updateItem(
    body: {
      itemId: string;
      quantity: number;
      message?: string;
      restaurantId: string;
      customizations: any[];
    },
    user_id: number,
  ) {
    return this.cartRepository.updateItem(body, user_id);
  }
}
