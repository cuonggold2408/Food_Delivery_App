import { Body, Controller, Post, Req } from '@nestjs/common';
import { CartBodyDTO } from 'src/routes/cart/cart.dto';
import { CartService } from 'src/routes/cart/cart.service';

@Controller('cart')
export class CartController {
  constructor(private readonly cartService: CartService) {}

  @Post()
  async addToCart(@Body() body: CartBodyDTO, @Req() req: any) {
    const user_id = req.user.user_id;
    return this.cartService.addToCart(body, user_id);
  }
}
