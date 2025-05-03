import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Query,
  Req,
} from '@nestjs/common';
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

  @Get('favorite')
  getFavoriteRestaurants(@Req() req: any) {
    const userId = req.user.user_id;
    return this.restaurantService.getFavoriteRestaurants(userId);
  }

  @Get(':id')
  @IsPublic()
  getRestaurantById(
    @Param('id') id: number,
    @Query('category') category?: string,
  ) {
    if (category) {
      return this.restaurantService.getRestaurantByIdAndByCategory(
        category,
        id,
      );
    }

    return this.restaurantService.getRestaurantById(id);
  }
  @Get('items/:id')
  @IsPublic()
  getItemsByRestaurantId(@Param('id') id: number, @Body() body: any) {
    return this.restaurantService.getItemsByRestaurantId(id, body.restaurantId);
  }

  @Post('favorite/:restaurantId')
  addFavoriteRestaurant(
    @Req() req: any,
    @Param('restaurantId') restaurantId: number,
  ) {
    const userId = req.user.user_id;
    return this.restaurantService.addFavoriteRestaurant(userId, restaurantId);
  }

  @Delete('favorite/:restaurantId')
  removeFavoriteRestaurant(
    @Req() req: any,
    @Param('restaurantId') restaurantId: number,
  ) {
    const userId = req.user.user_id;
    return this.restaurantService.removeFavoriteRestaurant(
      userId,
      restaurantId,
    );
  }
}
