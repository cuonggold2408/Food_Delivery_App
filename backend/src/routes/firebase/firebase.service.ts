import { BadRequestException, Injectable } from '@nestjs/common';
import { OrderStatus } from 'src/database/entities/order/order.entity';
import { RegisterDeviceTokenDto } from 'src/routes/firebase/firebase.dto';
import { FirebaseRepository } from 'src/routes/firebase/firebase.repo';

export interface OrderNotificationData {
  orderId: number;
  userId: number;
  status?: OrderStatus;
  restaurantName?: string;
  estimatedDeliveryTime?: Date;
  totalAmount?: string;
}

@Injectable()
export class FirebaseService {
  constructor(private readonly firebaseRepository: FirebaseRepository) {}

  private shouldSendNotification(status: OrderStatus): boolean {
    const importantStatuses = [
      OrderStatus.PENDING_PICKUP,
      OrderStatus.PENDING_DELIVERY,
      OrderStatus.DELIVERED,
      OrderStatus.CANCELLED,
    ];

    return importantStatuses.includes(status);
  }

  private formatEstimatedTime(estimatedTime: Date): string {
    const now = new Date();
    const diff = estimatedTime.getTime() - now.getTime();
    const minutes = Math.round(diff / (1000 * 60));

    if (minutes <= 0) {
      return 'ngay lập tức';
    } else if (minutes < 60) {
      return `${minutes} phút`;
    } else {
      const hours = Math.floor(minutes / 60);
      const remainingMinutes = minutes % 60;
      if (remainingMinutes === 0) {
        return `${hours} giờ`;
      } else {
        return `${hours} giờ ${remainingMinutes} phút`;
      }
    }
  }

  async registerDeviceToken(userId: number, body: RegisterDeviceTokenDto) {
    return this.firebaseRepository.registerDeviceToken(userId, body);
  }

  async unregisterDeviceToken(userId: number, deviceToken: string) {
    return this.firebaseRepository.unregisterDeviceToken(userId, deviceToken);
  }

  async deleteInvalidDeviceTokens(deviceToken: string) {
    return this.firebaseRepository.deleteInvalidDeviceTokens(deviceToken);
  }

  /**
   * Gửi thông báo khi trạng thái đơn hàng thay đổi
   */
  async notifyOrderStatusUpdate(data: OrderNotificationData): Promise<void> {
    if (!data.status) return;

    try {
      if (this.shouldSendNotification(data.status)) {
        const estimatedTime = data.estimatedDeliveryTime
          ? this.formatEstimatedTime(data.estimatedDeliveryTime)
          : undefined;

        await this.firebaseRepository.sendOrderStatusNotification({
          orderId: data.orderId,
          userId: data.userId,
          status: data.status,
          restaurantName: data.restaurantName,
          estimatedTime,
        });
      }
    } catch (error) {
      console.log('error: ', error);
      throw new BadRequestException(error);
    }
  }

  /**
   * Gửi thông báo khi đơn hàng được tạo
   */
  async notifyOrderCreated(data: OrderNotificationData): Promise<void> {
    if (!data.status) return;

    try {
      await this.firebaseRepository.sendToUser(data.userId, {
        title: '🛒 Đơn hàng đã được tạo',
        body: `Đơn hàng #${data.orderId} từ ${data.restaurantName} đã được tạo thành công. Tổng tiền: ${data.totalAmount}đ`,
        data: {
          type: 'order_created',
          orderId: data.orderId.toString(),
          restaurantName: data.restaurantName || '',
          totalAmount: data.totalAmount || '',
        },
      });
    } catch (error) {
      console.log('error: ', error);
      throw new BadRequestException(error);
    }
  }
}
