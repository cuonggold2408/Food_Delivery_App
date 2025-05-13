import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { MenuCategory } from 'src/database/entities/restaurant/category/menu-categories.entity';
import { UserFavoriteRestaurant } from 'src/database/entities/restaurant/favorite/user-favorite.entity';
import { RestaurantCategory } from 'src/database/entities/restaurant/restaurant-category.entity';
import { Restaurant } from 'src/database/entities/restaurant/restaurant.entity';
import { Repository } from 'typeorm';

@Injectable()
export class RestaurantRepository {
  constructor(
    @InjectRepository(Restaurant)
    private readonly restaurantRepository: Repository<Restaurant>,

    @InjectRepository(RestaurantCategory)
    private readonly categoryRepo: Repository<RestaurantCategory>,

    @InjectRepository(MenuCategory)
    private readonly menuCategoryRepo: Repository<MenuCategory>,

    @InjectRepository(UserFavoriteRestaurant)
    private readonly userFavoriteRepo: Repository<UserFavoriteRestaurant>,
  ) {}

  // Lấy tất cả nhà hàng và lọc theo khoảng cách
  async getRestaurantsWithLocation(
    page: number,
    limit: number,
    latitude: number,
    longitude: number,
    radius: number,
  ) {
    const skip = (page - 1) * limit;

    const queryBuilder = this.restaurantRepository
      .createQueryBuilder('restaurant')
      .addSelect(
        `ST_Distance(
            ST_SetSRID(ST_MakePoint(restaurant.longitude, restaurant.latitude), 4326),
            ST_SetSRID(ST_MakePoint(:longitude, :latitude), 4326)
        )`,
        'distance',
      )
      .where(
        `ST_Distance(
            ST_SetSRID(ST_MakePoint(restaurant.longitude, restaurant.latitude), 4326),
            ST_SetSRID(ST_MakePoint(:longitude, :latitude), 4326)
        ) <= :radius`,
        { latitude, longitude, radius },
      )
      .skip(skip)
      .take(limit)
      .orderBy('distance', 'ASC');

    const [restaurants, totalRestaurants] =
      await queryBuilder.getManyAndCount();

    return {
      currentPage: page,
      limit,
      total: totalRestaurants,
      data: restaurants,
    };
  }

  // Lọc theo danh mục và khoảng cách
  async getRestaurantsByCategoriesAndLocation(
    categoryNames: string[],
    page: number,
    limit: number,
    latitude: number,
    longitude: number,
    radius: number,
  ) {
    const skip = (page - 1) * limit;

    const queryBuilder = this.restaurantRepository
      .createQueryBuilder('restaurant')
      // .leftJoinAndSelect('restaurant.menuItems', 'menu_item')

      .leftJoin('restaurant.mappings', 'mapping')
      .leftJoin('mapping.category', 'category')
      .where('category.name IN (:...categoryNames)', { categoryNames })
      .addSelect(
        `ST_Distance(
            ST_SetSRID(ST_MakePoint(restaurant.longitude, restaurant.latitude), 4326),
            ST_SetSRID(ST_MakePoint(:longitude, :latitude), 4326)
        )`,
        'distance',
      )
      .andWhere(
        `ST_Distance(
            ST_SetSRID(ST_MakePoint(restaurant.longitude, restaurant.latitude), 4326),
            ST_SetSRID(ST_MakePoint(:longitude, :latitude), 4326)
        ) <= :radius`,
        { latitude, longitude, radius },
      )
      .skip(skip)
      .take(limit)
      .orderBy('distance', 'ASC');

    const [restaurants, totalRestaurants] =
      await queryBuilder.getManyAndCount();

    return {
      currentPage: page,
      limit,
      total: totalRestaurants,
      data: restaurants,
    };
  }

  async getRestaurantById(id: string) {
    const menuCategories = await this.menuCategoryRepo.find({
      where: { restaurant: { restaurant_id: id } },
      relations: ['menuItems', 'restaurant'],
    });

    const restaurant = await this.restaurantRepository.findOne({
      where: { restaurant_id: id },
    });

    if (!restaurant || !restaurant.is_active || !menuCategories) {
      throw new NotFoundException('Không tìm thấy nhà hàng');
    }

    return {
      ...restaurant,
      menuCategories: menuCategories.map((category) => ({
        category_id: category.categoryId,
        category_name: category.name,
        items: category.menuItems.map((item) => ({
          product_id: item.item_id,
          product_name: item.name,
          product_desc: item.description,
          product_price: item.price,
          product_image: item.image_url,
        })),
      })),
    };
  }

  async getRestaurantByIdAndByCategory(categoryName: string, id: string) {
    const cleanCategoryName = categoryName.trim().toLowerCase();
    const menuCategories = await this.menuCategoryRepo.find({
      where: { restaurant: { restaurant_id: id } },
      relations: ['menuItems'],
    });

    if (!menuCategories) {
      throw new NotFoundException('Không tìm thấy nhà hàng');
    }

    const category = menuCategories.find(
      (cat) => cat.name.trim().toLowerCase() === cleanCategoryName,
    );
    if (!category) {
      throw new NotFoundException('Không tìm thấy danh mục món ăn');
    }

    const items = category.menuItems;

    return items;
  }

  async getAllCategories() {
    return await this.categoryRepo.find();
  }

  async getItemsByRestaurantId(id: string, restaurantId: string) {
    const restaurant = await this.restaurantRepository.findOne({
      where: { restaurant_id: restaurantId },
      relations: [
        'menuItems',
        'menuItems.customizationMappings',
        'menuItems.customizationMappings.category',
        'menuItems.customizationMappings.category.options',
      ],
    });

    if (!restaurant) {
      throw new NotFoundException('Không tìm thấy nhà hàng');
    }

    const dishArr = restaurant.menuItems.filter((item) => item.item_id === id);
    if (dishArr.length === 0) {
      throw new NotFoundException('Không tìm thấy món ăn');
    }

    const dish = dishArr[0];

    return {
      restaurant_name: restaurant.name,
      item_id: dish.item_id,
      item_name: dish.name,
      item_desc: dish.description,
      item_price: dish.price,
      item_image: dish.image_url,
      options: dish.customizationMappings.map((option) => ({
        option_category: {
          category_id: option.category.categoryId,
          category_name: option.category.name,
          category_min_selections: option.category.minSelections,
          category_max_selections: option.category.maxSelections,
          option_dishes: option.category.options.map((option) => ({
            option_id: option.optionId,
            option_name: option.name,
            option_price: option.additionalPrice,
          })),
        },
      })),
    };
  }

  async getFavoriteRestaurants(userId: number) {
    return await this.userFavoriteRepo.find({
      where: {
        user_id: userId,
      },
      relations: ['restaurant'],
    });
  }

  async addFavoriteRestaurant(userId: number, restaurantId: string) {
    const restaurant = await this.restaurantRepository.findOne({
      where: { restaurant_id: restaurantId },
    });

    if (!restaurant) {
      throw new NotFoundException('Không tìm thấy nhà hàng');
    }

    const existing = await this.userFavoriteRepo.findOne({
      where: {
        user_id: userId,
        restaurant_id: restaurantId,
      },
    });

    if (existing) {
      throw new ConflictException('Nhà hàng đã có trong danh sách yêu thích');
    }

    const favorite = this.userFavoriteRepo.create({
      user_id: userId,
      restaurant_id: restaurantId,
    });

    await this.userFavoriteRepo.save(favorite);

    return 'Thêm vào danh sách yêu thích thành công';
  }

  async removeFavoriteRestaurant(userId: number, restaurantId: string) {
    const favorite = await this.userFavoriteRepo.findOne({
      where: {
        user_id: userId,
        restaurant_id: restaurantId,
      },
    });

    if (!favorite) {
      throw new NotFoundException(
        'Không tìm thấy nhà hàng trong danh sách yêu thích',
      );
    }

    await this.userFavoriteRepo.remove(favorite);

    return 'Xóa khỏi danh sách yêu thích thành công';
  }
}
