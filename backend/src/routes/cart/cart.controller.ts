import { Body, Controller, Param, Patch, Post, Req } from '@nestjs/common';
import { ApiOperation } from '@nestjs/swagger';
import { CartBodyDTO, CartItemBodyDTO } from 'src/routes/cart/cart.dto';
import { CartService } from 'src/routes/cart/cart.service';

@Controller('cart')
export class CartController {
  constructor(private readonly cartService: CartService) {}

  @Post()
  @ApiOperation({ summary: 'Thêm món ăn vào giỏ hàng' })
  async addToCart(@Body() body: CartBodyDTO, @Req() req: any) {
    const user_id = req.user.user_id;
    return this.cartService.addToCart(body, user_id);
  }

  @Patch(':cartItemId')
  @ApiOperation({ summary: 'Cập nhật thông tin món ăn trong giỏ hàng' })
  async updateItemCart(
    @Param('cartItemId') cartItemId: number,
    @Body() body: CartItemBodyDTO,
    @Req() req: any,
  ) {
    const user_id = req.user.user_id;
    return this.cartService.updateItemCart(cartItemId, body, user_id);
  }
}
