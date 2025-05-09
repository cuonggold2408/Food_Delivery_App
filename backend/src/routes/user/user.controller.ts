import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  Req,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import {
  UserAddressBodyDTO,
  UserProfileBodyDTO,
} from 'src/routes/user/user.dto';
import { UserService } from 'src/routes/user/user.service';

@Controller('user')
@ApiBearerAuth()
export class UserController {
  constructor(private readonly userService: UserService) {}

  // Address
  @Post('address')
  @ApiOperation({ summary: 'Lưu địa chỉ' })
  saveAddress(@Body() body: UserAddressBodyDTO, @Req() req: any) {
    // Lấy user_id từ request
    const user_id = req.user.user_id;

    return this.userService.saveAddress(body, user_id);
  }

  @Put('address/:addressId')
  @ApiOperation({ summary: 'Cập nhật địa chỉ' })
  updateAddress(
    @Param('addressId') addressId: number,
    @Req() req: any,
    @Body() body: Omit<UserAddressBodyDTO, 'user_id'>,
  ) {
    const userId = req.user.user_id;
    return this.userService.updateAddress(addressId, userId, body);
  }

  @Delete('address/:addressId')
  @ApiOperation({ summary: 'Xóa địa chỉ' })
  deleteAddress(@Param('addressId') addressId: number, @Req() req: any) {
    const userId = req.user.user_id;
    return this.userService.deleteAddress(addressId, userId);
  }

  @Get('address')
  @ApiOperation({ summary: 'Lấy danh sách địa chỉ' })
  getAllAddress(@Req() req: any) {
    const userId = req.user.user_id;
    return this.userService.getAllAddress(userId);
  }

  // User Profile
  @Get('profile')
  @ApiOperation({ summary: 'Lấy thông tin cá nhân' })
  getUserProfile(@Req() req: any) {
    const userId = req.user.user_id;
    return this.userService.getUserProfile(userId);
  }

  @Put('profile')
  @ApiOperation({ summary: 'Cập nhật thông tin cá nhân' })
  updateUserProfile(@Body() body: UserProfileBodyDTO, @Req() req: any) {
    const userId = req.user.user_id;
    return this.userService.updateUserProfile(userId, body);
  }
}
