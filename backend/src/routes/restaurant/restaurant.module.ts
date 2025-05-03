import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MenuItem } from 'src/database/entities/menu-item.entity';
import { MenuCategory } from 'src/database/entities/restaurant/category/menu-categories.entity';
import { UserFavoriteRestaurant } from 'src/database/entities/restaurant/favorite/user-favorite.entity';
import { RestaurantCategory } from 'src/database/entities/restaurant/restaurant-category.entity';
import { Restaurant } from 'src/database/entities/restaurant/restaurant.entity';
import { RestaurantController } from 'src/routes/restaurant/restaurant.controller';
import { RestaurantRepository } from 'src/routes/restaurant/restaurant.repo';
import { RestaurantService } from 'src/routes/restaurant/restaurant.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      MenuItem,
      Restaurant,
      RestaurantCategory,
      MenuCategory,
      UserFavoriteRestaurant,
    ]),
  ],
  controllers: [RestaurantController],
  providers: [RestaurantService, RestaurantRepository],
})
export class RestaurantModule {}
