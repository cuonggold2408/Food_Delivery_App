import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
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
  ) {}
  async getRestaurantsWithMenuItems(skip: number, take: number) {
    return this.restaurantRepository.find({
      skip,
      take,
      relations: ['menuItems'],
    });
  }

  async getRestaurantsByCategories(
    categoryNames: string[],
    skip: number,
    take: number,
  ) {
    return this.restaurantRepository
      .createQueryBuilder('restaurant')
      .leftJoinAndSelect('restaurant.menuItems', 'menu_item')
      .leftJoinAndSelect('restaurant.mappings', 'mapping')
      .leftJoinAndSelect('mapping.category', 'category')
      .where('category.name IN (:...categoryNames)', { categoryNames })
      .skip(skip)
      .take(take)
      .getMany();
  }

  async getRestaurantById(id: number) {
    const restaurant = await this.restaurantRepository.findOne({
      where: { restaurant_id: id },
      relations: ['menuItems'],
    });

    if (!restaurant) {
      throw new NotFoundException('Không tìm thấy nhà hàng');
    }

    return restaurant;
  }

  async getAllCategories() {
    return await this.categoryRepo.find();
  }
}
