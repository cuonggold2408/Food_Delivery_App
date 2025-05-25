import { Body, Controller, Post, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiBody, ApiOperation } from '@nestjs/swagger';
import { CreateOrderDTO } from 'src/routes/order/order.dto';
import { OrderService } from 'src/routes/order/order.service';

@Controller('orders')
export class OrderController {
  constructor(private readonly orderService: OrderService) {}

  @Post()
  @ApiOperation({ summary: 'Tạo đơn hàng' })
  @ApiBody({ type: CreateOrderDTO })
  @ApiBearerAuth()
  async createOrder(@Body() body: CreateOrderDTO, @Req() req: any) {
    const userId = req.user.user_id;
    return this.orderService.createOrder(body, userId);
  }
}
