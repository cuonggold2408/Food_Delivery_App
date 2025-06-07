import { Injectable } from '@nestjs/common';
import { AddRestaurantBodyType } from 'src/routes/admin/admin.model';
import { AdminRepository } from 'src/routes/admin/admin.repo';

@Injectable()
export class AdminService {
  constructor(private readonly adminRepository: AdminRepository) {}

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
}
