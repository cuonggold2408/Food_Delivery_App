import { BadRequestException, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { MenuItem } from 'src/database/entities/menu-item.entity';
import { Order, OrderStatus } from 'src/database/entities/order/order.entity';
import { CustomizationCategory } from 'src/database/entities/restaurant/category/customization-category.entity';
import { ItemCustomizationCategory } from 'src/database/entities/restaurant/category/item-customization-category.entity';
import { MenuCategory } from 'src/database/entities/restaurant/category/menu-categories.entity';
import { Restaurant } from 'src/database/entities/restaurant/restaurant.entity';
import {
  AddFoodBodyType,
  AddFoodCategoryBodyType,
  AddRestaurantBodyType,
} from 'src/routes/admin/admin.model';
import { FirebaseRepository } from 'src/routes/firebase/firebase.repo';
import { Repository } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class AdminRepository {
  constructor(
    @InjectRepository(Restaurant)
    private readonly restaurantRepository: Repository<Restaurant>,

    @InjectRepository(MenuItem)
    private readonly menuItemRepository: Repository<MenuItem>,

    @InjectRepository(MenuCategory)
    private readonly menuCategoryRepository: Repository<MenuCategory>,

    @InjectRepository(ItemCustomizationCategory)
    private readonly itemCustomizationCategoryRepository: Repository<ItemCustomizationCategory>,

    @InjectRepository(CustomizationCategory)
    private readonly customizationCategoryRepository: Repository<CustomizationCategory>,

    @InjectRepository(Order)
    private readonly orderRepository: Repository<Order>,

    private readonly firebaseRepository: FirebaseRepository,
  ) {}

  /**
   * Nhà hàng
   */
  async addRestaurant(
    body: Omit<AddRestaurantBodyType, 'restaurant_id' | 'rating' | 'is_active'>,
  ) {
    const { name, city, shop_image_url, latitude, longitude } = body;

    if (!name || !city || !shop_image_url || !latitude || !longitude) {
      throw new BadRequestException('Thiếu thông tin');
    }

    const restaurant_id = uuidv4().replace(/-/g, '').slice(0, 12);

    const roundedLatitude = Number(latitude.toFixed(8));
    const roundedLongitude = Number(longitude.toFixed(8));

    const restaurant = await this.restaurantRepository.findOne({
      where: {
        latitude: roundedLatitude,
        longitude: roundedLongitude,
      },
    });

    if (restaurant) {
      throw new BadRequestException('Nhà hàng đã tồn tại');
    }

    const newRestaurant = this.restaurantRepository.create({
      name,
      city,
      shop_image_url,
      latitude,
      longitude,
      restaurant_id,
    });

    return this.restaurantRepository.save(newRestaurant);
  }

  async updateRestaurant(
    restaurant_id: string,
    body: Omit<AddRestaurantBodyType, 'restaurant_id' | 'rating' | 'is_active'>,
  ) {
    const { name, city, shop_image_url, latitude, longitude } = body;

    const restaurant = await this.restaurantRepository.findOne({
      where: {
        restaurant_id,
      },
    });

    if (!restaurant) {
      throw new BadRequestException('Nhà hàng không tồn tại');
    }

    const roundedLatitude = Number(latitude?.toFixed(8));
    const roundedLongitude = Number(longitude?.toFixed(8));

    const updatedRestaurant = this.restaurantRepository.create({
      ...restaurant,
      name,
      city,
      shop_image_url,
      latitude: roundedLatitude || restaurant.latitude,
      longitude: roundedLongitude || restaurant.longitude,
    });

    return this.restaurantRepository.save(updatedRestaurant);
  }

  async deleteRestaurant(restaurant_id: string) {
    const restaurant = await this.restaurantRepository.findOne({
      where: {
        restaurant_id,
      },
    });

    if (!restaurant) {
      throw new BadRequestException('Nhà hàng không tồn tại');
    }
    await this.restaurantRepository.update(restaurant_id, {
      is_active: false,
    });

    return {
      message: 'Xóa nhà hàng thành công',
    };
  }

  async activeRestaurant(restaurant_id: string) {
    const restaurant = await this.restaurantRepository.findOne({
      where: {
        restaurant_id,
      },
    });

    if (!restaurant) {
      throw new BadRequestException('Nhà hàng không tồn tại');
    }

    await this.restaurantRepository.update(restaurant_id, {
      is_active: true,
    });

    return {
      message: 'Active nhà hàng thành công',
    };
  }

  async getAllRestaurant(page: number, limit: number) {
    const skip = (page - 1) * limit;
    const [restaurants, total] = await this.restaurantRepository.findAndCount({
      where: {
        is_active: true,
      },
      skip,
      take: limit,
    });

    return {
      restaurants,
      total,
    };
  }

  async getRestaurant(restaurant_id: string) {
    const restaurant = await this.restaurantRepository.findOne({
      where: {
        restaurant_id,
      },
      relations: ['menuItems'],
    });

    if (!restaurant) {
      throw new BadRequestException('Nhà hàng không tồn tại');
    }

    return restaurant;
  }

  /**
   * Món ăn
   */
  async addFood(restaurant_id: string, body: AddFoodBodyType) {
    const { name, description, price, image_url } = body;

    const generate_item_id = uuidv4().replace(/-/g, '').slice(0, 12);

    const item_id = `IT${generate_item_id}`;

    const newFood = this.menuItemRepository.create({
      item_id,
      name,
      description,
      price,
      image_url,
      restaurant: {
        restaurant_id,
      },
    });

    return this.menuItemRepository.save(newFood);
  }

  async addFoodCategory(
    restaurant_id: string,
    item_id: string,
    body: AddFoodCategoryBodyType,
  ) {
    const { name } = body;

    const generate_category_id = uuidv4().replace(/-/g, '').slice(0, 12);

    const category_id = `CAT${generate_category_id}`;

    // Tạo CustomizationCategory
    const newCustomizationCategory =
      this.customizationCategoryRepository.create({
        categoryId: category_id,
        name,
        restaurantId: {
          restaurant_id,
        },
      });
    await this.customizationCategoryRepository.save(newCustomizationCategory);

    // Tạo mapping giữa item và customization category
    const newItemCustomization =
      this.itemCustomizationCategoryRepository.create({
        itemId: item_id,
        categoryId: category_id,
      });
    await this.itemCustomizationCategoryRepository.save(newItemCustomization);

    const newMenuCategory = this.menuCategoryRepository.create({
      categoryId: category_id,
      name,
      restaurant: {
        restaurant_id,
      },
    });
    await this.menuCategoryRepository.save(newMenuCategory);

    await this.menuItemRepository.update(
      { item_id, restaurant: { restaurant_id } },
      {
        menuCategory: {
          categoryId: category_id,
        },
      },
    );

    return {
      message: 'Thêm danh mục cho món ăn thành công',
    };
  }

  async updateFood(
    restaurant_id: string,
    item_id: string,
    body: AddFoodBodyType,
  ) {
    const { name, description, price, image_url } = body;

    await this.menuItemRepository.update(
      { item_id, restaurant: { restaurant_id } },
      {
        name,
        description,
        price,
        image_url,
      },
    );

    return {
      message: 'Sửa món ăn thành công',
    };
  }

  async deleteFood(restaurant_id: string, item_id: string) {
    await this.menuItemRepository.update(
      { item_id, restaurant: { restaurant_id } },
      { is_available: false },
    );

    return {
      message: 'Cập nhật tình trạng món ăn thành công',
    };
  }

  async activeFood(restaurant_id: string, item_id: string) {
    await this.menuItemRepository.update(
      { item_id, restaurant: { restaurant_id } },
      { is_available: true },
    );

    return {
      message: 'Active món ăn thành công',
    };
  }

  /**
   * Quản lý order
   */

  async getOrders(page: number, limit: number) {
    const skip = (page - 1) * limit;
    const [orders, total] = await this.orderRepository.findAndCount({
      skip,
      take: limit,
      where: {
        order_status: OrderStatus.PENDING_PICKUP,
      },
      relations: ['restaurant', 'payment'],
    });

    return {
      orders,
      total,
    };
  }

  async doneOrder(order_id: string) {
    // Lấy thông tin đơn hàng với relations để có thông tin user và restaurant
    const order = await this.orderRepository.findOne({
      where: { order_id: parseInt(order_id) },
      relations: ['user', 'restaurant'],
    });

    if (!order) {
      throw new BadRequestException('Đơn hàng không tồn tại');
    }

    // Cập nhật trạng thái đơn hàng
    await this.orderRepository.update(order_id, {
      order_status: OrderStatus.PENDING_DELIVERY,
    });

    // Gửi thông báo đẩy cho user
    try {
      await this.firebaseRepository.sendOrderStatusNotification({
        orderId: parseInt(order_id),
        userId: order.user.user_id,
        status: OrderStatus.PENDING_DELIVERY,
        restaurantName: order.restaurant.name,
      });
    } catch (error) {
      console.error('Lỗi khi gửi thông báo:', error);
    }

    return {
      message: 'Done order thành công',
    };
  }
}
