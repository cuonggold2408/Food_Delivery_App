import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { RestaurantCategory } from 'src/database/entities/restaurant/restaurant-category.entity';
import { RestaurantRepository } from 'src/routes/restaurant/restaurant.repo';
import { Repository } from 'typeorm';

@Injectable()
export class RestaurantService {
  constructor(
    private readonly restaurantRepository: RestaurantRepository,
    @InjectRepository(RestaurantCategory)
    private readonly categoryRepo: Repository<RestaurantCategory>,
  ) {}
  async getAllRestaurants(page: number, limit: number) {
    // Tính skip
    const skip = (page - 1) * limit;

    // Lấy dữ liệu kèm menuItems
    const restaurants =
      await this.restaurantRepository.getRestaurantsWithMenuItems(skip, limit);

    const result = restaurants.map((rest) => ({
      shop_id: rest.restaurant_id,
      shop_name: rest.name,
      shop_address: rest.street_address,
      shop_image: rest.shop_image_url,
      city: rest.city,
      products: rest.menuItems.map((item) => ({
        product_name: item.name,
        product_desc: item.description,
        product_price: item.price,
        product_image: item.image_url,
      })),
    }));

    return {
      currentPage: page,
      limit,
      data: result,
    };
  }

  async getAllRestaurantsByCategories(
    categoryNames: string[],
    page: number,
    limit: number,
  ) {
    const skip = (page - 1) * limit;

    if (!categoryNames || categoryNames.length === 0) {
      throw new BadRequestException('Phải có ít nhất một category để lọc');
    }

    // Lấy các category có thật
    const validCategories = await this.categoryRepo.find({
      where: categoryNames.map((name) => ({ name })),
    });

    if (validCategories.length === 0) {
      throw new NotFoundException('Không có category nào hợp lệ');
    }

    const restaurants =
      await this.restaurantRepository.getRestaurantsByCategories(
        validCategories.map((c) => c.name),
        skip,
        limit,
      );

    const grouped = {
      categories: categoryNames,
      shops: restaurants.map((rest) => ({
        shop_id: rest.restaurant_id,
        shop_name: rest.name,
        shop_address: rest.street_address,
        shop_image: rest.shop_image_url,
        city: rest.city,
        products: rest.menuItems.map((item) => ({
          product_name: item.name,
          product_desc: item.description,
          product_price: item.price,
          product_image: item.image_url,
        })),
      })),
    };

    return {
      currentPage: page,
      limit,
      data: grouped,
    };
  }

  async getRestaurantById(id: number) {
    const restaurant = await this.restaurantRepository.getRestaurantById(id);
    return {
      ...restaurant,
      restaurant_id: undefined,
      menuItems: restaurant.menuItems.map((item) => ({
        product_name: item.name,
        product_desc: item.description,
        product_price: item.price,
        product_image: item.image_url,
        product_is_available: item.is_available,
      })),
    };
  }

  async getAllCategories() {
    const categories = await this.restaurantRepository.getAllCategories();

    return {
      categories: categories.map((category) => ({
        category_name: category.name,
        category_image: category.image_url,
      })),
    };
  }
}
