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
import {
  UserAddressBodyDTO,
  UserProfileBodyDTO,
} from 'src/routes/user/user.dto';
import { UserService } from 'src/routes/user/user.service';

@Controller('user')
export class UserController {
  constructor(private readonly userService: UserService) {}

  // Address
  @Post('address')
  saveAddress(@Body() body: UserAddressBodyDTO, @Req() req: any) {
    // Lấy user_id từ request
    const user_id = req.user.user_id;

    return this.userService.saveAddress(body, user_id);
  }

  @Put('address/:addressId')
  updateAddress(
    @Param('addressId') addressId: number,
    @Req() req: any,
    @Body() body: Omit<UserAddressBodyDTO, 'user_id'>,
  ) {
    const userId = req.user.user_id;
    return this.userService.updateAddress(addressId, userId, body);
  }

  @Delete('address/:addressId')
  deleteAddress(@Param('addressId') addressId: number, @Req() req: any) {
    const userId = req.user.user_id;
    return this.userService.deleteAddress(addressId, userId);
  }

  @Get('address')
  getAllAddress(@Req() req: any) {
    const userId = req.user.user_id;
    return this.userService.getAllAddress(userId);
  }

  // User Profile
  @Get('profile')
  getUserProfile(@Req() req: any) {
    const userId = req.user.user_id;
    return this.userService.getUserProfile(userId);
  }

  @Put('profile')
  updateUserProfile(@Body() body: UserProfileBodyDTO, @Req() req: any) {
    const userId = req.user.user_id;
    return this.userService.updateUserProfile(userId, body);
  }
}
