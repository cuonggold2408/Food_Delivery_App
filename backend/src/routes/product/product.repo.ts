import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Restaurant } from 'src/database/entities/restaurant/restaurant.entity';
import { Repository } from 'typeorm';

@Injectable()
export class ProductRepository {
  constructor(
    @InjectRepository(Restaurant)
    private readonly restaurantRepository: Repository<Restaurant>,
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
}
