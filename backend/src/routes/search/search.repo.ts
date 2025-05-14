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

  async search(
    latitude: number,
    longitude: number,
    query: string,
    limit: number,
    skip: number,
    radius: number,
    minRating?: number,
    minPrice?: number,
    maxPrice?: number,
    nearMe?: boolean,
  ) {
    const keyword = `%${query.toLowerCase()}%`;

    const restaurantQueryBuilder = this.restaurantRepository
      .createQueryBuilder('restaurant')
      .where(`unaccent(LOWER(restaurant.name)) LIKE unaccent(:keyword)`, {
        keyword,
      });

    if (minRating !== undefined) {
      restaurantQueryBuilder.andWhere('restaurant.rating >= :minRating', {
        minRating,
      });
    }

    if (
      latitude !== undefined &&
      longitude !== undefined &&
      radius !== undefined
    ) {
      restaurantQueryBuilder
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
        );

      if (nearMe) {
        restaurantQueryBuilder.orderBy('distance', 'ASC');
      } else {
        restaurantQueryBuilder.orderBy('restaurant.rating', 'DESC');
      }
    } else {
      restaurantQueryBuilder.orderBy('restaurant.rating', 'DESC');
    }

    const [restaurants, totalRestaurants] = await restaurantQueryBuilder
      .take(limit)
      .skip(skip)
      .getManyAndCount();

    const menuItemQueryBuilder = this.menuItemRepository
      .createQueryBuilder('item')
      .leftJoinAndSelect('item.restaurant', 'restaurant')
      .where(`unaccent(LOWER(item.name)) LIKE unaccent(:keyword)`, { keyword });

    if (minRating !== undefined) {
      menuItemQueryBuilder.andWhere('restaurant.rating >= :minRating', {
        minRating,
      });
    }

    if (minPrice !== undefined) {
      menuItemQueryBuilder.andWhere(
        'CAST(item.price AS DECIMAL) >= :minPrice',
        { minPrice },
      );
    }

    if (maxPrice !== undefined) {
      menuItemQueryBuilder.andWhere(
        'CAST(item.price AS DECIMAL) <= :maxPrice',
        { maxPrice },
      );
    }

    if (
      latitude !== undefined &&
      longitude !== undefined &&
      radius !== undefined
    ) {
      menuItemQueryBuilder
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
        );

      if (nearMe) {
        menuItemQueryBuilder.orderBy('distance', 'ASC');
      } else {
        menuItemQueryBuilder.orderBy('restaurant.rating', 'DESC');
      }
    } else {
      menuItemQueryBuilder.orderBy('restaurant.rating', 'DESC');
    }

    const [menuItems, totalMenuItems] = await menuItemQueryBuilder
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
