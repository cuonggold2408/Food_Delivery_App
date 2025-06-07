import { Injectable } from '@nestjs/common';
import {
  AddFoodBodyType,
  AddFoodCategoryBodyType,
  AddRestaurantBodyType,
} from 'src/routes/admin/admin.model';
import { AdminRepository } from 'src/routes/admin/admin.repo';

@Injectable()
export class AdminService {
  constructor(private readonly adminRepository: AdminRepository) {}

  /**
   * Nhà hàng
   */
  async addRestaurant(
    body: Omit<AddRestaurantBodyType, 'restaurant_id' | 'rating' | 'is_active'>,
  ) {
    return this.adminRepository.addRestaurant(body);
  }

  async updateRestaurant(
    restaurant_id: string,
    body: Omit<AddRestaurantBodyType, 'restaurant_id' | 'rating' | 'is_active'>,
  ) {
    return this.adminRepository.updateRestaurant(restaurant_id, body);
  }

  async deleteRestaurant(restaurant_id: string) {
    return this.adminRepository.deleteRestaurant(restaurant_id);
  }

  async activeRestaurant(restaurant_id: string) {
    return this.adminRepository.activeRestaurant(restaurant_id);
  }

  async getAllRestaurant(page: number, limit: number) {
    return this.adminRepository.getAllRestaurant(page, limit);
  }

  async getRestaurant(restaurant_id: string) {
    return this.adminRepository.getRestaurant(restaurant_id);
  }

  /**
   * Món ăn
   */
  async addFood(restaurant_id: string, body: AddFoodBodyType) {
    return this.adminRepository.addFood(restaurant_id, body);
  }

  async addFoodCategory(
    restaurant_id: string,
    item_id: string,
    body: AddFoodCategoryBodyType,
  ) {
    return this.adminRepository.addFoodCategory(restaurant_id, item_id, body);
  }

  async updateFood(
    restaurant_id: string,
    item_id: string,
    body: AddFoodBodyType,
  ) {
    return this.adminRepository.updateFood(restaurant_id, item_id, body);
  }

  async deleteFood(restaurant_id: string, item_id: string) {
    return this.adminRepository.deleteFood(restaurant_id, item_id);
  }

  async activeFood(restaurant_id: string, item_id: string) {
    return this.adminRepository.activeFood(restaurant_id, item_id);
  }

  async getOrders(page: number, limit: number) {
    return this.adminRepository.getOrders(page, limit);
  }

  async doneOrder(order_id: string) {
    return this.adminRepository.doneOrder(order_id);
  }
}
