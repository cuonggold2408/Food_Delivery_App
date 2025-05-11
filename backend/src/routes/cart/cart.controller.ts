import { Body, Controller, Get, Post, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { CartBodyDTO } from 'src/routes/cart/cart.dto';
import { CartService } from 'src/routes/cart/cart.service';

@Controller('cart')
@ApiBearerAuth()
export class CartController {
  constructor(private readonly cartService: CartService) {}

  @Get('/')
  @ApiOperation({ summary: 'Lấy danh sách giỏ hàng của 1 user' })
  async getCart(@Req() req: any) {
    const user_id = req.user.user_id;
    return this.cartService.getCart(user_id);
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
