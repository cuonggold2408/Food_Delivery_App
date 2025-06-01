import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Post,
  Put,
  Req,
  Request,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Order, OrderStatus } from 'src/database/entities/order/order.entity';
import { RegisterDeviceTokenDto } from 'src/routes/firebase/firebase.dto';
import { FirebaseRepository } from 'src/routes/firebase/firebase.repo';
import { FirebaseService } from 'src/routes/firebase/firebase.service';
import { Repository } from 'typeorm';

export class UpdateOrderStatusDto {
  newStatus: OrderStatus;
  estimatedDeliveryTime?: string;
}

@Controller('firebase/notifications')
export class FirebaseController {
  constructor(
    private readonly firebaseService: FirebaseService,
    private readonly firebaseRepository: FirebaseRepository,

    @InjectRepository(Order)
    private readonly orderRepository: Repository<Order>,
  ) {}

  /**
   * Cập nhật trạng thái đơn hàng và gửi thông báo
   */
  @Put(':orderId/status')
  async updateOrderStatus(
    @Param('orderId', ParseIntPipe) orderId: number,
    @Body() updateDto: UpdateOrderStatusDto,
  ) {
    // Tìm đơn hàng
    const order = await this.orderRepository.findOne({
      where: { order_id: orderId },
      relations: ['user', 'restaurant'],
    });

    if (!order) {
      throw new Error(`Order with ID ${orderId} not found`);
    }

    // Cập nhật trạng thái
    order.order_status = updateDto.newStatus;

    if (updateDto.estimatedDeliveryTime) {
      order.estimated_delivery_time = new Date(updateDto.estimatedDeliveryTime);
    }

    // Lưu thay đổi
    const updatedOrder = await this.orderRepository.save(order);

    // Gửi thông báo
    await this.firebaseService.notifyOrderStatusUpdate({
      orderId: orderId,
      userId: order.user.user_id,
      status: updateDto.newStatus,
      restaurantName: order.restaurant.name,
      estimatedDeliveryTime: order.estimated_delivery_time,
    });

    return {
      success: true,
      message: 'Order status updated successfully',
      data: {
        orderId: updatedOrder.order_id,
        newStatus: updatedOrder.order_status,
        estimatedDeliveryTime: updatedOrder.estimated_delivery_time,
      },
    };
  }

  // Đăng ký device token cho user hiện tại
  @Post('register-device')
  async registerDevice(
    @Body() body: RegisterDeviceTokenDto,
    @Request() req: any,
  ) {
    const { user_id } = req.user;
    return this.firebaseService.registerDeviceToken(user_id, body);
  }

  @Delete('unregister-device')
  async unregisterDevice(
    @Body() body: { deviceToken: string },
    @Request() req: any,
  ) {
    const { user_id } = req.user;
    return this.firebaseService.unregisterDeviceToken(
      user_id,
      body.deviceToken,
    );
  }

  @Get('test')
  async sendTestNotification(@Req() req: any) {
    const { user_id } = req.user;
    await this.firebaseRepository.sendToUser(user_id, {
      title: '🔔 Test Notification',
      body: 'This is a test notification from Food Delivery App!',
      data: {
        type: 'test',
        timestamp: new Date().toISOString(),
      },
    });

    return {
      success: true,
      message: `Test notification sent to user ${user_id}`,
    };
  }
}
