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
}
