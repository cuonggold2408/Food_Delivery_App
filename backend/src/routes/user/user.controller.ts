import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { UserAddressBodyDTO } from 'src/routes/user/user.dto';
import { UserService } from 'src/routes/user/user.service';

@Controller('user')
export class UserController {
  constructor(private readonly userService: UserService) {}

  @Post('address')
  saveAddress(@Body() body: UserAddressBodyDTO) {
    return this.userService.saveAddress(body);
  }

  @Get('addresses/:userId')
  getAllAddress(@Param('userId') userId: number) {
    return this.userService.getAllAddress(userId);
  }
}
