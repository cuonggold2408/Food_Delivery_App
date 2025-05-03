import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { MenuItem } from 'src/database/entities/menu-item.entity';
import { Restaurant } from 'src/database/entities/restaurant/restaurant.entity';
import { Repository } from 'typeorm';

@Injectable()
export class SearchRepository {
  constructor(
    @InjectRepository(Restaurant)
    private readonly restaurantRepository: Repository<Restaurant>,

    @InjectRepository(MenuItem)
    private readonly menuItemRepository: Repository<MenuItem>,
  ) {}
  async search(query: string, limit: number, skip: number) {
    const keyword = `%${query.toLowerCase()}%`;

    const [restaurants, totalRestaurants] = await this.restaurantRepository
      .createQueryBuilder('restaurant')
      .where(`unaccent(LOWER(restaurant.name)) LIKE unaccent(:keyword)`, {
        keyword,
      })
      .orderBy('restaurant.rating', 'DESC')
      .take(limit)
      .skip(skip)
      .getManyAndCount();

    const [menuItems, totalMenuItems] = await this.menuItemRepository
      .createQueryBuilder('item')
      .leftJoinAndSelect('item.restaurant', 'restaurant')
      .where(`unaccent(LOWER(item.name)) LIKE unaccent(:keyword)`, { keyword })
      .orderBy('restaurant.rating', 'DESC')
      .take(limit)
      .skip(skip)
      .getManyAndCount();

    return {
      restaurants: {
        total: totalRestaurants,
        data: restaurants,
      },
      menuItems: {
        total: totalMenuItems,
        data: menuItems,
      },
    };
  }
}
