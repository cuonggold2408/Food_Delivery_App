import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
} from '@nestjs/common';
import { UserAddressBodyDTO } from 'src/routes/user/user.dto';
import { UserService } from 'src/routes/user/user.service';

@Controller('user')
export class UserController {
  constructor(private readonly userService: UserService) {}

  @Post('address')
  saveAddress(@Body() body: UserAddressBodyDTO) {
    return this.userService.saveAddress(body);
  }

  @Put('address/:addressId/:userId')
  updateAddress(
    @Param('addressId') addressId: number,
    @Param('userId') userId: number,
    @Body() body: Omit<UserAddressBodyDTO, 'user_id'>,
  ) {
    return this.userService.updateAddress(addressId, userId, body);
  }

  @Delete('address/:addressId/:userId')
  deleteAddress(
    @Param('addressId') addressId: number,
    @Param('userId') userId: number,
  ) {
    return this.userService.deleteAddress(addressId, userId);
  }

  @Get('address/:userId')
  getAllAddress(@Param('userId') userId: number) {
    return this.userService.getAllAddress(userId);
  }
}
