import { Injectable } from '@nestjs/common';
import { CartBodyType, CartItemBodyType } from 'src/routes/cart/cart.model';
import { CartRepository } from 'src/routes/cart/cart.repo';

@Injectable()
export class CartService {
  constructor(private readonly cartRepository: CartRepository) {}

  async addToCart(body: CartBodyType, user_id: number) {
    return this.cartRepository.addToCart(body, user_id);
  }

  async updateItemCart(
    cartItemId: number,
    body: CartItemBodyType,
    user_id: number,
  ) {
    return this.cartRepository.updateItemCart(cartItemId, body, user_id);
  }
}
