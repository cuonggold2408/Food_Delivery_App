import { Controller, Get, Param, Query } from '@nestjs/common';
import { RestaurantService } from 'src/routes/restaurant/restaurant.service';
import { IsPublic } from 'src/shared/decorators/auth.decorator';

@Controller('restaurants')
export class RestaurantController {
  constructor(private readonly restaurantService: RestaurantService) {}

  @Get('/')
  @IsPublic()
  getAllRestaurants(
    @Query('category') category?: string,
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 10,
  ) {
    const categories = category
      ? category.split(',').map((c) => c.trim().toLowerCase())
      : [];

    if (categories.length > 0) {
      return this.restaurantService.getAllRestaurantsByCategories(
        categories,
        page,
        limit,
      );
    }

    return this.restaurantService.getAllRestaurants(page, limit);
  }

  @Get('categories')
  @IsPublic()
  getAllCategories() {
    return this.restaurantService.getAllCategories();
  }

  @Get(':id')
  @IsPublic()
  getRestaurantById(@Param('id') id: number) {
    return this.restaurantService.getRestaurantById(id);
  }
}
