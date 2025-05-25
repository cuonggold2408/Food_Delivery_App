import { BadRequestException, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { CartItemCustomization } from 'src/database/entities/cart/cart-item-customization.entity';
import { CartItem } from 'src/database/entities/cart/cart-item.entity';
import { Cart } from 'src/database/entities/cart/cart.entity';
import { MenuItem } from 'src/database/entities/menu-item.entity';
import { Restaurant } from 'src/database/entities/restaurant/restaurant.entity';
import { CartBodyType } from 'src/routes/cart/cart.model';
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

  // So sánh option của sản phẩm user gửi lên với option của sản phẩm trong database
  private compareCustomizations(
    existingCustomizations: CartItemCustomization[],
    newCustomizations: { option_id: number }[],
  ): boolean {
    if (existingCustomizations.length !== newCustomizations.length) {
      return false;
    }

    const existingOptionIds = existingCustomizations
      .map((c) => c.option_id)
      .sort();
    const newOptionIds = newCustomizations.map((c) => c.option_id).sort();

    return JSON.stringify(existingOptionIds) === JSON.stringify(newOptionIds);
  }

  async addToCart(
    { restaurant_id, item_id, quantity, message, customizations }: CartBodyType,
    user_id: number,
  ) {
    try {
      if (!restaurant_id || !item_id || !quantity) {
        throw new BadRequestException('Không đủ thông tin');
      }

      if (quantity <= 0) {
        throw new BadRequestException('Số lượng phải lớn hơn 0');
      }

      const restaurant = await this.restaurantRepository.findOne({
        where: { restaurant_id },
      });
      if (!restaurant) {
        throw new BadRequestException('Cửa hàng không tồn tại');
      }

      const checkItemInRestaurant = await this.menuItemRepository.findOne({
        where: { item_id, restaurant: { restaurant_id } },
        relations: ['customizationMappings.category.options'],
      });
      if (!checkItemInRestaurant) {
        throw new BadRequestException('Món ăn không tồn tại trong cửa hàng');
      }

      // Tìm giỏ hàng tồn tại cho user và cửa hàng hoặc tạo mới
      let cart = await this.cartRepository.findOne({
        where: {
          user: { user_id },
          restaurant: { restaurant_id },
        },
      });

      if (!cart) {
        // Tạo giỏ hàng mới nếu không tồn tại
        cart = this.cartRepository.create({
          user: { user_id },
          restaurant: { restaurant_id },
        });
        await this.cartRepository.save(cart);
      }

      // Kiểm tra xem món ăn đã tồn tại trong giỏ hàng chưa
      const existingCartItem = await this.cartItemRepository.find({
        where: {
          cart: { cart_id: cart.cart_id },
          menuItem: { item_id },
        },
        relations: [
          'menuItem',
          'menuItem.customizationMappings',
          'menuItem.customizationMappings.category',
        ],
      });

      console.log('existingCartItem: ', existingCartItem);

      if (existingCartItem.length > 0) {
        // Duyệt qua từng cart item để kiểm tra customizations
        for (const cartItem of existingCartItem) {
          // Lấy customizations của cart item hiện tại
          const cartItemCustomizations =
            await this.cartItemCustomizationRepository.find({
              where: {
                cart_item_id: cartItem.cart_item_id,
              },
              relations: ['option'],
            });

          // console.log('Cart Item Customizations:', cartItemCustomizations);
          // console.log(
          //   'Menu Item Customization Categories:',
          //   cartItem.menuItem.customizationMappings,
          // );

          // So sánh customizations
          const isSameCustomizations = this.compareCustomizations(
            cartItemCustomizations,
            customizations || [],
          );

          if (isSameCustomizations) {
            // Nếu tìm thấy cart item có cùng customizations, tăng quantity
            cartItem.quantity += quantity;

            // Tính lại tổng tiền dựa trên giá gốc và options
            const basePrice = parseFloat(cartItem.menuItem.price);
            const optionPrices = cartItemCustomizations.reduce(
              (total, custom) => total + parseFloat(custom.price_option),
              0,
            );
            const pricePerItem = basePrice + optionPrices;
            cartItem.total_pay = (pricePerItem * cartItem.quantity).toString();

            cartItem.message = message || cartItem.message;
            await this.cartItemRepository.save(cartItem);
            return 'Cập nhật thông tin sản phẩm trong giỏ hàng thành công';
          }
        }
      }

      // Tính tổng tiền của các options được chọn
      let totalOptionPrice = 0;
      if (
        customizations &&
        customizations.length > 0 &&
        customizations[0] !== null
      ) {
        // Duyệt qua từng category và options của món ăn
        checkItemInRestaurant.customizationMappings.forEach((mapping) => {
          mapping.category.options.forEach((option) => {
            // Kiểm tra xem option này có được user chọn không
            const isSelected = customizations.some(
              (custom) => custom.option_id.toString() === option.optionId,
            );
            if (isSelected) {
              totalOptionPrice += parseFloat(option.additionalPrice);
            }
          });
        });
      }

      // Tính tổng tiền của món ăn (giá gốc + giá options)
      const basePrice = parseFloat(checkItemInRestaurant.price);
      const totalPrice = (basePrice + totalOptionPrice) * quantity;

      // Nếu không tìm thấy cart item nào có cùng customizations, tạo mới
      const newCartItem = this.cartItemRepository.create({
        cart: { cart_id: cart.cart_id },
        menuItem: { item_id },
        quantity,
        message,
        total_pay: totalPrice.toString(),
      });
      await this.cartItemRepository.save(newCartItem);

      // Thêm customizations nếu có

      if (
        customizations &&
        customizations.length > 0 &&
        customizations[0] !== null
      ) {
        const customizationsToSave = await Promise.all(
          customizations.map(async (customization) => {
            // Tìm option trong database để lấy giá
            const option = checkItemInRestaurant.customizationMappings
              .flatMap((mapping) => mapping.category.options)
              .find(
                (opt) => opt.optionId === customization.option_id.toString(),
              );

            return {
              cart_item_id: newCartItem.cart_item_id,
              option_id: customization.option_id,
              price_option: option?.additionalPrice || '0',
            };
          }),
        );

        await this.cartItemCustomizationRepository.save(customizationsToSave);
      }

      return 'Thêm sản phẩm vào giỏ hàng thành công';
    } catch (error) {
      console.log('error: ', error);
      throw new BadRequestException('Có lỗi xảy ra');
    }
  }

  async getCartOfUser(user_id: number) {
    const cart = await this.cartRepository.find({
      where: { user: { user_id } },
      relations: ['restaurant', 'items'],
    });
    if (!cart) {
      throw new BadRequestException('User không có giỏ hàng');
    }
    const cartResponse = cart.map((c) => ({
      ...c.restaurant,
      // Trả về số lượng item và tổng tiền
      total_item: c.items.length,
      total_pay: c.items.reduce(
        (acc, item) => acc + parseFloat(item.total_pay),
        0,
      ),
    }));
    return cartResponse;
  }

  async getCart(user_id: number, restaurantId: string) {
    const cart = await this.cartRepository.findOne({
      where: { user: { user_id }, restaurant: { restaurant_id: restaurantId } },
      relations: [
        'items',
        'items.customizations.option',
        'restaurant',
        'restaurant.promotions',
      ],
    });
    console.log('cart: ', cart);

    if (!cart) {
      return null;
    }
    // Tính tổng số lượng các món trong giỏ hàng
    const quantity_item = cart.items.reduce(
      (acc, item) => acc + item.quantity,
      0,
    );

    // Tính tổng tiền phải trả cho giỏ hàng
    const total_pay = cart.items.reduce(
      (acc, item) => acc + parseFloat(item.total_pay),
      0,
    );

    // Tạo mảng items với thông tin món ăn
    const items = cart.items.map((item) => {
      // Tạo tên các option nếu có nhiều option
      const option_names = item.customizations
        ? item.customizations
            .map((customization) => customization.option.name)
            .join(', ')
        : '';

      return {
        image_dish: item.menuItem.image_url,
        name_dish: item.menuItem.name,
        option_name: option_names, // Tên các option
        message: item.message || '', // Nếu có message
        total_pay: parseFloat(item.total_pay).toFixed(0).toString(),
        quantity: item.quantity,
      };
    });

    return {
      quantity_item,
      total_pay: total_pay.toString(),
      restaurant_name: cart.restaurant.name,
      promotions: cart.restaurant.promotions,
      items,
    };
  }

  async deleteAllItemFromCart(restaurantId: string, user_id: number) {
    const cart = await this.cartRepository.findOne({
      where: { user: { user_id }, restaurant: { restaurant_id: restaurantId } },
    });

    if (!cart) {
      throw new BadRequestException('User không có giỏ hàng');
    }
    await this.cartRepository.delete(cart.cart_id);
    return 'Xóa tất cả món ăn khỏi giỏ hàng thành công';
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
    const cart = await this.cartRepository.findOne({
      where: {
        user: { user_id },
        restaurant: { restaurant_id: body.restaurantId },
      },
    });

    if (!cart) {
      throw new BadRequestException('User không có giỏ hàng');
    }

    // Tìm tất cả các cart items có cùng item_id
    const cartItems = await this.cartItemRepository.find({
      where: {
        cart: { cart_id: cart.cart_id },
        menuItem: { item_id: body.itemId },
      },
      relations: ['menuItem'],
    });

    if (cartItems.length === 0) {
      throw new BadRequestException('Món ăn không tồn tại trong giỏ hàng');
    }

    // Nếu có customizations, tìm item có cùng customizations
    let targetItem = cartItems[0]; // Mặc định lấy item đầu tiên nếu không có customizations
    if (body.customizations && body.customizations.length > 0) {
      for (const cartItem of cartItems) {
        const cartItemCustomizations =
          await this.cartItemCustomizationRepository.find({
            where: {
              cart_item_id: cartItem.cart_item_id,
            },
            relations: ['option'],
          });

        const isSameCustomizations = this.compareCustomizations(
          cartItemCustomizations,
          body.customizations,
        );

        if (isSameCustomizations) {
          targetItem = cartItem;
          break;
        }
      }
    }

    if (body.quantity === 0) {
      await this.cartItemRepository.delete(targetItem.cart_item_id);
      return 'Xoá món ăn thành công';
    }

    targetItem.message = body.message || '';
    if (targetItem.quantity < body.quantity) {
      targetItem.total_pay = (
        parseFloat(targetItem.total_pay) +
        (parseFloat(targetItem.total_pay) / targetItem.quantity) *
          (body.quantity - targetItem.quantity)
      ).toString();
    } else if (targetItem.quantity >= body.quantity) {
      targetItem.total_pay = (
        parseFloat(targetItem.total_pay) -
        (parseFloat(targetItem.total_pay) / targetItem.quantity) *
          (targetItem.quantity - body.quantity)
      ).toString();
    }
    targetItem.quantity = body.quantity;

    await this.cartItemRepository.update(targetItem.cart_item_id, {
      message: targetItem.message,
      quantity: targetItem.quantity,
      total_pay: targetItem.total_pay,
    });
    return 'Cập nhật thông tin sản phẩm trong giỏ hàng thành công';
  }
}
