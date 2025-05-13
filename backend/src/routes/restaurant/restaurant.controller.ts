import {
  BadRequestException,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Query,
  Req,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiQuery,
  ApiResponse,
} from '@nestjs/swagger';
import { RestaurantService } from 'src/routes/restaurant/restaurant.service';
import { IsPublic } from 'src/shared/decorators/auth.decorator';

@Controller('restaurants')
export class RestaurantController {
  constructor(private readonly restaurantService: RestaurantService) {}

  @Get('/')
  @IsPublic()
  @ApiOperation({ summary: 'Lấy danh sách các nhà hàng' })
  @ApiResponse({ status: 200, description: 'Return list of restaurants' })
  @ApiQuery({
    name: 'category',
    required: false,
    description: 'Filter by category',
  })
  @ApiQuery({
    name: 'latitude',
    required: true,
    description: 'Vĩ độ của người dùng',
  })
  @ApiQuery({
    name: 'longitude',
    required: true,
    description: 'Kinh độ của người dùng',
  })
  @ApiQuery({
    name: 'radius',
    required: false,
    description: 'Bán kính tính bằng mét (mặc định 10000 mét)',
    type: Number,
  })
  getAllRestaurants(
    @Query('latitude') latitude: number, // Vị trí của người dùng
    @Query('longitude') longitude: number, // Vị trí của người dùng
    @Query('category') category?: string,
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 10,
    @Query('radius') radius: number = 10000,
  ) {
    if (!latitude || !longitude) {
      throw new BadRequestException(
        'Vị trí người dùng cần thiết để xác định các nhà hàng gần bạn.',
      );
    }

    const categories = category
      ? category.split(',').map((c) => c.trim().toLowerCase())
      : [];

    if (categories.length > 0) {
      return this.restaurantService.getAllRestaurantsByCategories(
        categories,
        page,
        limit,
        latitude,
        longitude,
        radius,
      );
    }

    return this.restaurantService.getAllRestaurants(
      page,
      limit,
      latitude,
      longitude,
      radius,
    );
  }

  @Get('categories')
  @IsPublic()
  @ApiOperation({ summary: 'Lấy danh sách tất cả các danh mục' })
  @ApiResponse({ status: 200, description: 'Return list of categories' })
  getAllCategories() {
    return this.restaurantService.getAllCategories();
  }

  @Get('favorite')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Lấy danh sách các nhà hàng yêu thích' })
  getFavoriteRestaurants(@Req() req: any) {
    const userId = req.user.user_id;
    return this.restaurantService.getFavoriteRestaurants(userId);
  }

  @Get(':restaurantId')
  @IsPublic()
  @ApiOperation({ summary: 'Lấy thông tin chi tiết của 1 nhà hàng' })
  @ApiResponse({ status: 200, description: 'Return restaurant details' })
  @ApiQuery({
    name: 'category',
    required: false,
    description: 'Filter by category',
  })
  getRestaurantById(
    @Param('restaurantId') id: string,
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

  @Get('items/:itemId')
  @IsPublic()
  @ApiOperation({ summary: 'Lấy chi tiết của 1 món ăn trong 1 nhà hàng' })
  @ApiResponse({ status: 200, description: 'Return restaurant items' })
  getItemsByRestaurantId(
    @Param('itemId') id: string,
    @Query('restaurantId') restaurantId: string,
  ) {
    return this.restaurantService.getItemsByRestaurantId(id, restaurantId);
  }

  @Post('favorite/:restaurantId')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Thêm 1 nhà hàng vào danh sách yêu thích' })
  addFavoriteRestaurant(
    @Req() req: any,
    @Param('restaurantId') restaurantId: string,
  ) {
    const userId = req.user.user_id;
    return this.restaurantService.addFavoriteRestaurant(userId, restaurantId);
  }

  @Delete('favorite/:restaurantId')
  @ApiOperation({ summary: 'Xóa 1 nhà hàng khỏi danh sách yêu thích' })
  @ApiBearerAuth()
  removeFavoriteRestaurant(
    @Req() req: any,
    @Param('restaurantId') restaurantId: string,
  ) {
    const userId = req.user.user_id;
    return this.restaurantService.removeFavoriteRestaurant(
      userId,
      restaurantId,
    );
  }
}
