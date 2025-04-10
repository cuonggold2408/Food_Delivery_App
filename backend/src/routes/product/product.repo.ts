import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Restaurant } from 'src/database/entities/restaurant.entity';
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
}
