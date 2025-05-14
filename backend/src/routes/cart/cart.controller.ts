import {
  Body,
  Controller,
  Delete,
  Get,
  Patch,
  Post,
  Query,
  Req,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiBody,
  ApiOperation,
  ApiQuery,
} from '@nestjs/swagger';
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

  @Delete('/items')
  @ApiOperation({
    summary: 'Xóa tất cả món ăn khỏi giỏ hàng',
  })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        restaurantId: { type: 'string' },
      },
    },
  })
  async deleteAllItemFromCart(
    @Body() body: { restaurantId: string },
    @Req() req: any,
  ) {
    const user_id = req.user.user_id;
    return this.cartService.deleteAllItemFromCart(body.restaurantId, user_id);
  }

  @Patch('/item')
  @ApiOperation({
    summary: 'Cập nhật số lượng món ăn và message trong giỏ hàng',
  })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        itemId: { type: 'string' },
        quantity: { type: 'number' },
        message: { type: 'string', default: null },
        restaurantId: { type: 'string' },
        customizations: { type: 'array', default: [] },
      },
    },
  })
  async updateItem(
    @Body()
    body: {
      itemId: string;
      quantity: number;
      message?: string;
      restaurantId: string;
      customizations: any[];
    },
    @Req() req: any,
  ) {
    const user_id = req.user.user_id;
    return this.cartService.updateItem(body, user_id);
  }
}
