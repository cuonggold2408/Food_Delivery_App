import { Injectable } from '@nestjs/common';
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

  async getAllRestaurants(
    page: number,
    limit: number,
    latitude: number,
    longitude: number,
    radius: number,
  ) {
    return this.restaurantRepository.getRestaurantsWithLocation(
      page,
      limit,
      latitude,
      longitude,
      radius,
    );
  }

  async getAllRestaurantsByCategories(
    categoryNames: string[],
    page: number,
    limit: number,
    latitude: number,
    longitude: number,
    radius: number,
  ) {
    return this.restaurantRepository.getRestaurantsByCategoriesAndLocation(
      categoryNames,
      page,
      limit,
      latitude,
      longitude,
      radius,
    );
  }

  async getRestaurantById(id: string) {
    return await this.restaurantRepository.getRestaurantById(id);
  }

  async getRestaurantByIdAndByCategory(categoryName: string, id: string) {
    return await this.restaurantRepository.getRestaurantByIdAndByCategory(
      categoryName,
      id,
    );
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

  async getItemsByRestaurantId(id: string, restaurantId: string) {
    return await this.restaurantRepository.getItemsByRestaurantId(
      id,
      restaurantId,
    );
  }

  async getFavoriteRestaurants(userId: number) {
    return await this.restaurantRepository.getFavoriteRestaurants(userId);
  }

  async addFavoriteRestaurant(userId: number, restaurantId: string) {
    return await this.restaurantRepository.addFavoriteRestaurant(
      userId,
      restaurantId,
    );
  }

  async removeFavoriteRestaurant(userId: number, restaurantId: string) {
    return await this.restaurantRepository.removeFavoriteRestaurant(
      userId,
      restaurantId,
    );
  }
}
