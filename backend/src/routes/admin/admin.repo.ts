import { BadRequestException, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Restaurant } from 'src/database/entities/restaurant/restaurant.entity';
import { AddRestaurantBodyType } from 'src/routes/admin/admin.model';
import { Repository } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class AdminRepository {
  constructor(
    @InjectRepository(Restaurant)
    private readonly restaurantRepository: Repository<Restaurant>,
  ) {}

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
    });

    if (!restaurant) {
      throw new BadRequestException('Nhà hàng không tồn tại');
    }

    return restaurant;
  }
}
