import {
  BadRequestException,
  ConflictException,
  Injectable,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { CartItemCustomization } from 'src/database/entities/cart/cart-item-customization.entity';
import { CartItem } from 'src/database/entities/cart/cart-item.entity';
import { Cart } from 'src/database/entities/cart/cart.entity';
import { MenuItem } from 'src/database/entities/menu-item.entity';
import { Restaurant } from 'src/database/entities/restaurant/restaurant.entity';
import { CartBodyType, CartItemBodyType } from 'src/routes/cart/cart.model';
import { Repository } from 'typeorm';

@Injectable()
export class CartRepository {
  constructor(
    @InjectRepository(Cart)
    private readonly cartRepository: Repository<Cart>,

    @InjectRepository(CartItem)
    private readonly cartItemRepository: Repository<CartItem>,

    @InjectRepository(CartItemCustomization)
    private readonly cartItemCustomizationRepository: Repository<CartItemCustomization>,

    @InjectRepository(Restaurant)
    private readonly restaurantRepository: Repository<Restaurant>,

    @InjectRepository(MenuItem)
    private readonly menuItemRepository: Repository<MenuItem>,
  ) {}

  async addToCart(
    {
      restaurant_id,
      item_id,
      quantity,
      total_pay,
      message,
      customizations,
    }: CartBodyType,
    user_id: number,
  ) {
    if (!restaurant_id || !item_id || !quantity || !total_pay) {
      throw new BadRequestException('Không đủ thông tin');
    }

    if (quantity <= 0) {
      throw new BadRequestException('Số lượng phải lớn hơn 0');
    }

    if (parseFloat(total_pay) <= 0) {
      throw new BadRequestException('Tổng tiền phải lớn hơn 0');
    }

    const restaurant = await this.restaurantRepository.findOne({
      where: { restaurant_id },
    });
    if (!restaurant) {
      throw new BadRequestException('Cửa hàng không tồn tại');
    }

    const menuItem = await this.menuItemRepository.findOne({
      where: { item_id },
    });
    if (!menuItem) {
      throw new BadRequestException('Món ăn không tồn tại');
    }

    const cart = await this.cartRepository.findOne({
      where: {
        user: { user_id },
        restaurant: { restaurant_id },
      },
    });
    if (cart) {
      throw new ConflictException('Giỏ hàng đã tồn tại');
    }
    const newCart = this.cartRepository.create({
      user: { user_id },
      restaurant: { restaurant_id },
    });
    await this.cartRepository.save(newCart);
    const newCartItem = new CartItem();
    newCartItem.cart = newCart;
    newCartItem.menuItem = { item_id } as any;
    newCartItem.total_pay = total_pay;
    newCartItem.quantity = quantity;
    newCartItem.message = message;

    await this.cartItemRepository.save(newCartItem);
    if (customizations) {
      await this.cartItemCustomizationRepository.save(
        customizations.map((customization) => ({
          ...customization,
          cart_item_id: newCartItem.cart_item_id,
          option_id: customization.option_id,
        })),
      );
    }

    return 'Thêm vào giỏ hàng thành công';
  }

  async updateItemCart(
    cartItemId: number,
    { quantity, total_pay, message, customizations, item_id }: CartItemBodyType,
    user_id: number,
  ) {
    if (!quantity || !total_pay) {
      throw new BadRequestException('Không đủ thông tin');
    }

    if (quantity <= 0) {
      throw new BadRequestException('Số lượng phải lớn hơn 0');
    }

    if (parseFloat(total_pay) <= 0) {
      throw new BadRequestException('Tổng tiền phải lớn hơn 0');
    }

    const cart = await this.cartRepository.findOne({
      where: {
        cart_id: cartItemId,
        user: { user_id },
      },
    });
    if (!cart) {
      throw new BadRequestException('Giỏ hàng không tồn tại');
    }

    const cartItem = await this.cartItemRepository.findOne({
      where: { cart_item_id: cartItemId, menuItem: { item_id } },
    });
    if (!cartItem) {
      throw new BadRequestException('Món ăn không tồn tại');
    }

    cartItem.quantity = quantity;
    cartItem.total_pay = total_pay;
    cartItem.message = message;

    if (customizations) {
      // 1. Xóa tất cả customizations cũ của cart item
      await this.cartItemCustomizationRepository.delete({
        cart_item_id: cartItem.cart_item_id,
      });

      // 2. Thêm các customizations mới
      await this.cartItemCustomizationRepository.save(
        customizations.map((customization) => ({
          cart_item_id: cartItem.cart_item_id,
          option_id: customization.option_id,
        })),
      );
    }

    await this.cartItemRepository.save(cartItem);

    return 'Cập nhật giỏ hàng thành công';
  }
}
