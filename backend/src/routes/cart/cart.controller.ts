import { Body, Controller, Get, Post, Query, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiQuery } from '@nestjs/swagger';
import { CartBodyDTO } from 'src/routes/cart/cart.dto';
import { CartService } from 'src/routes/cart/cart.service';

@Controller('cart')
@ApiBearerAuth()
export class CartController {
  constructor(private readonly cartService: CartService) {}

  @Get('/')
  @ApiOperation({ summary: 'Lấy giỏ hàng trong 1 nhà hàng' })
  @ApiQuery({
    name: 'restaurantId',
    description: 'ID của nhà hàng',
  })
  async getCart(@Req() req: any, @Query('restaurantId') restaurantId: string) {
    const user_id = req.user.user_id;
    return this.cartService.getCart(user_id, restaurantId);
  }

  @Get('/all')
  @ApiOperation({ summary: 'Lấy danh sách giỏ hàng của 1 user' })
  async getCartOfUser(@Req() req: any) {
    const user_id = req.user.user_id;
    return this.cartService.getCartOfUser(user_id);
  }

  @Post()
  @ApiOperation({
    summary:
      'Thêm món ăn vào giỏ hàng hoặc cập nhật thông tin sản phẩm trong giỏ hàng',
  })
  async addToCart(@Body() body: CartBodyDTO, @Req() req: any) {
    const user_id = req.user.user_id;
    return this.cartService.addToCart(body, user_id);
  }
}
