import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiBody, ApiOperation } from '@nestjs/swagger';
import {
  AddFoodBodyDTO,
  AddFoodCategoryBodyDTO,
  AddRestaurantBodyDTO,
  CreateDiscountCodeBodyDTO,
} from 'src/routes/admin/admin.dto';
import { AdminService } from 'src/routes/admin/admin.service';

@Controller('admin')
@ApiBearerAuth()
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  /**
   * Xem đánh giá và phản hồi
   */

  // Xem đánh giá và phản hồi
  @Get('restaurant/reviews')
  @ApiOperation({ summary: 'Xem đánh giá và phản hồi' })
  async getReviews() {
    return this.adminService.getReviews();
  }

  // Xem review của 1 nhà hàng
  @Get('restaurant/:restaurant_id/reviews')
  @ApiOperation({ summary: 'Xem review của 1 nhà hàng' })
  async getReviewsByRestaurant(@Param('restaurant_id') restaurant_id: string) {
    return this.adminService.getReviewsByRestaurant(restaurant_id);
  }

  // Reply review
  @Post('restaurant/reviews/:review_id/reply')
  @ApiOperation({ summary: 'Reply review' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        review_reply: { type: 'string' },
      },
    },
  })
  async replyReview(
    @Param('review_id') review_id: string,
    @Body() body: { review_reply: string },
  ) {
    return this.adminService.replyReview(review_id, body);
  }

  /**
   Restaurant 
   */

  // Thêm nhà hàng
  @Post('restaurant')
  @ApiBody({ type: AddRestaurantBodyDTO })
  @ApiOperation({ summary: 'Thêm nhà hàng' })
  async addRestaurant(
    @Body()
    body: Omit<AddRestaurantBodyDTO, 'restaurant_id' | 'rating' | 'is_active'>,
  ) {
    return this.adminService.addRestaurant(body);
  }

  // Sửa nhà hàng
  @Put('restaurant/:restaurant_id')
  @ApiBody({ type: AddRestaurantBodyDTO })
  @ApiOperation({ summary: 'Sửa nhà hàng' })
  async updateRestaurant(
    @Param('restaurant_id') restaurant_id: string,
    @Body()
    body: Omit<AddRestaurantBodyDTO, 'restaurant_id' | 'rating' | 'is_active'>,
  ) {
    return this.adminService.updateRestaurant(restaurant_id, body);
  }

  // Xóa nhà hàng
  @Delete('restaurant/:restaurant_id')
  @ApiOperation({ summary: 'Xóa nhà hàng' })
  async deleteRestaurant(@Param('restaurant_id') restaurant_id: string) {
    return this.adminService.deleteRestaurant(restaurant_id);
  }

  // Active nhà hàng
  @Put('restaurant/:restaurant_id/active')
  @ApiOperation({ summary: 'Active nhà hàng' })
  async activeRestaurant(@Param('restaurant_id') restaurant_id: string) {
    return this.adminService.activeRestaurant(restaurant_id);
  }

  // Lấy danh sách nhà hàng
  @Get('restaurants')
  @ApiOperation({ summary: 'Lấy danh sách nhà hàng' })
  async getAllRestaurant(
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 10,
  ) {
    return this.adminService.getAllRestaurant(page, limit);
  }

  // Lấy thông tin 1 nhà hàng
  @Get('restaurant/:restaurant_id')
  @ApiOperation({ summary: 'Lấy thông tin 1 nhà hàng' })
  async getRestaurant(@Param('restaurant_id') restaurant_id: string) {
    return this.adminService.getRestaurant(restaurant_id);
  }

  /**
   * Món ăn
   */

  // Thêm món ăn
  @Post('restaurant/:restaurant_id/food')
  @ApiBody({ type: AddFoodBodyDTO })
  @ApiOperation({ summary: 'Thêm món ăn' })
  async addFood(
    @Param('restaurant_id') restaurant_id: string,
    @Body() body: AddFoodBodyDTO,
  ) {
    return this.adminService.addFood(restaurant_id, body);
  }

  // Thêm danh mục cho món ăn
  @Post('restaurant/:restaurant_id/food/:item_id/category')
  @ApiBody({ type: AddFoodCategoryBodyDTO })
  @ApiOperation({ summary: 'Thêm danh mục cho món ăn' })
  async addFoodCategory(
    @Param('restaurant_id') restaurant_id: string,
    @Param('item_id') item_id: string,
    @Body() body: AddFoodCategoryBodyDTO,
  ) {
    return this.adminService.addFoodCategory(restaurant_id, item_id, body);
  }

  // Sửa món ăn
  @Put('restaurant/:restaurant_id/food/:item_id')
  @ApiBody({ type: AddFoodBodyDTO })
  @ApiOperation({ summary: 'Sửa món ăn' })
  async updateFood(
    @Param('restaurant_id') restaurant_id: string,
    @Param('item_id') item_id: string,
    @Body() body: AddFoodBodyDTO,
  ) {
    return this.adminService.updateFood(restaurant_id, item_id, body);
  }

  // Xóa món ăn hoặc hết hàng
  @Delete('restaurant/:restaurant_id/food/:item_id')
  @ApiOperation({ summary: 'Xóa món ăn hoặc hết hàng' })
  async deleteFood(
    @Param('restaurant_id') restaurant_id: string,
    @Param('item_id') item_id: string,
  ) {
    return this.adminService.deleteFood(restaurant_id, item_id);
  }

  // Active món ăn
  @Put('restaurant/:restaurant_id/food/:item_id/active')
  @ApiOperation({ summary: 'Active món ăn' })
  async activeFood(
    @Param('restaurant_id') restaurant_id: string,
    @Param('item_id') item_id: string,
  ) {
    return this.adminService.activeFood(restaurant_id, item_id);
  }

  // Hiển thị danh sách order
  @Get('orders')
  @ApiOperation({ summary: 'Hiển thị danh sách order' })
  async getOrders(
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 10,
  ) {
    return this.adminService.getOrders(page, limit);
  }

  // Done order bắn thông báo đẩy đến user
  @Put('orders/:order_id/done')
  @ApiOperation({ summary: 'Done order bắn thông báo đẩy đến user' })
  async doneOrder(@Param('order_id') order_id: string) {
    return this.adminService.doneOrder(order_id);
  }

  /**
   * Quản lý user
   */

  // Hiển thị danh sách user
  @Get('users')
  @ApiOperation({ summary: 'Hiển thị danh sách user' })
  async getUsers(
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 10,
  ) {
    return this.adminService.getUsers(page, limit);
  }

  // Block user
  @Put('users/:user_id/block')
  @ApiOperation({ summary: 'Block user' })
  async blockUser(@Param('user_id') user_id: string) {
    return this.adminService.blockUser(user_id);
  }

  // Unblock user
  @Put('users/:user_id/unblock')
  @ApiOperation({ summary: 'Unblock user' })
  async unblockUser(@Param('user_id') user_id: string) {
    return this.adminService.unblockUser(user_id);
  }

  /**
   * Báo cáo và phân tích doanh thu
   */

  // Hiển thị báo cáo và phân tích doanh thu
  @Get('report')
  @ApiOperation({ summary: 'Hiển thị báo cáo và phân tích doanh thu' })
  async getReport() {
    return this.adminService.getReport();
  }

  /**
   * Tạo mã giảm giá cho từng nhà hàng
   */

  // Tạo mã giảm giá cho từng nhà hàng
  @Post('restaurant/:restaurant_id/discount-code')
  @ApiOperation({ summary: 'Tạo mã giảm giá cho từng nhà hàng' })
  async createDiscountCode(
    @Param('restaurant_id') restaurant_id: string,
    @Body() body: CreateDiscountCodeBodyDTO,
  ) {
    return this.adminService.createDiscountCode(restaurant_id, body);
  }
}
