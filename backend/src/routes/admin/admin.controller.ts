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
import { AddRestaurantBodyDTO } from 'src/routes/admin/admin.dto';
import { AdminService } from 'src/routes/admin/admin.service';

@Controller('admin')
@ApiBearerAuth()
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

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
}
