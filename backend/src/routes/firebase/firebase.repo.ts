import { Inject, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { OrderStatus } from 'src/database/entities/order/order.entity';
import { UserDevice } from 'src/database/entities/user-device.entity';
import { RegisterDeviceTokenDto } from 'src/routes/firebase/firebase.dto';
import { Repository } from 'typeorm';
import * as admin from 'firebase-admin';

export interface NotificationPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
}

export interface OrderStatusNotification {
  orderId: number;
  userId: number;
  status: OrderStatus;
  restaurantName?: string;
  estimatedTime?: string;
}

@Injectable()
export class FirebaseRepository {
  constructor(
    @Inject('FIREBASE_ADMIN') private firebaseAdmin: typeof admin,
    @InjectRepository(UserDevice)
    private readonly userDeviceRepository: Repository<UserDevice>,
  ) {}

  // Đăng ký device token cho user hiện tại
  async registerDeviceToken(userId: number, body: RegisterDeviceTokenDto) {
    const { deviceToken, deviceType } = body;
    const userDevice = await this.userDeviceRepository.findOne({
      where: { user_id: userId, device_token: deviceToken },
    });
    if (userDevice) {
      userDevice.device_type = deviceType;
      userDevice.is_active = true;
      userDevice.updated_at = new Date();
      await this.userDeviceRepository.save(userDevice);
    } else {
      const newDevice = this.userDeviceRepository.create({
        user_id: userId,
        device_token: deviceToken,
        device_type: deviceType,
        is_active: true,
      });
      await this.userDeviceRepository.save(newDevice);
    }
  }

  // Hủy đăng ký device token
  // Hàm này được gọi khi user đăng xuất khỏi ứng dụng
  async unregisterDeviceToken(userId: number, deviceToken: string) {
    const userDevice = await this.userDeviceRepository.findOne({
      where: { user_id: userId, device_token: deviceToken },
    });
    if (userDevice) {
      userDevice.is_active = false;
      userDevice.updated_at = new Date();
      await this.userDeviceRepository.save(userDevice);
    }
    return {
      message: 'Device token unregistered successfully',
    };
  }

  // Xóa token không hợp lệ khỏi database
  async deleteInvalidDeviceTokens(deviceToken: string) {
    await this.userDeviceRepository.delete({ device_token: deviceToken });
    return {
      message: 'Device token deleted successfully',
    };
  }

  // Gửi thông báo đến một device token cụ thể
  async sendToDevice(
    deviceToken: string,
    payload: NotificationPayload,
  ): Promise<boolean> {
    try {
      const message: admin.messaging.Message = {
        token: deviceToken,
        notification: {
          title: payload.title,
          body: payload.body,
        },
        data: payload.data || {},
        android: {
          // Thông báo cho Android
          notification: {
            channelId: 'order_updates', // Tạo channel trong AndroidManifest.xml
            priority: 'high' as any, // high: thông báo ngay, low: thông báo sau
            sound: 'default', // default: âm thanh mặc định
            icon: 'ic_notification', // icon của thông báo
          },
        },
        apns: {
          // Thông báo cho iOS
          payload: {
            aps: {
              alert: {
                title: payload.title,
                body: payload.body,
              },
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      const response = await this.firebaseAdmin.messaging().send(message);
      console.log('response: ', response);

      return true;
    } catch (error) {
      // Nếu token không hợp lệ, xóa khỏi database
      if (error.code === 'messaging/registration-token-not-registered') {
        await this.deleteInvalidDeviceTokens(deviceToken);
      }

      return false;
    }
  }

  // Gửi thông báo đến tất cả các device token của user
  async sendToUser(
    userId: number,
    payload: NotificationPayload,
  ): Promise<number> {
    const userDevices = await this.userDeviceRepository.find({
      where: { user_id: userId, is_active: true },
    });

    if (userDevices.length === 0) {
      console.warn(`No active devices found for user ${userId}`);
      return 0;
    }

    let successCount = 0;
    const promises = userDevices.map(async (device) => {
      const success = await this.sendToDevice(device.device_token, payload);
      if (success) successCount++;
    });

    await Promise.all(promises);

    console.log(
      `Sent notifications to ${successCount}/${userDevices.length} devices for user ${userId}`,
    );
    return successCount;
  }

  /**
   * Gửi thông báo cập nhật trạng thái đơn hàng
   */
  async sendOrderStatusNotification(
    notification: OrderStatusNotification,
  ): Promise<void> {
    const { title, body, data } = this.buildOrderStatusMessage(notification);

    await this.sendToUser(notification.userId, {
      title,
      body,
      data,
    });
  }

  /**
   * Xây dựng message cho thông báo trạng thái đơn hàng
   */
  private buildOrderStatusMessage(
    notification: OrderStatusNotification,
  ): NotificationPayload {
    const {
      orderId,
      status,
      restaurantName,
      estimatedTime = '20 phút',
    } = notification;

    let title: string;
    let body: string;

    switch (status) {
      case OrderStatus.PENDING_PAYMENT:
        title = '💳 Thanh toán đơn hàng';
        body = `Vui lòng thanh toán cho đơn hàng #${orderId}`;
        break;

      case OrderStatus.PENDING_PICKUP:
        title = '👨‍🍳 Đơn hàng đã được xác nhận';
        body = `${restaurantName} đang chuẩn bị đơn hàng #${orderId} của bạn`;
        break;

      case OrderStatus.PENDING_DELIVERY:
        title = '🚴‍♂️ Đơn hàng đang được giao';
        body = `Đơn hàng #${orderId} đang trên đường đến bạn${estimatedTime ? ` (dự kiến ${estimatedTime})` : ''}`;
        break;

      case OrderStatus.DELIVERED:
        title = '✅ Đơn hàng đã giao thành công';
        body = `Đơn hàng #${orderId} đã được giao đến bạn. Cảm ơn bạn đã sử dụng dịch vụ!`;
        break;

      case OrderStatus.CANCELLED:
        title = '❌ Đơn hàng đã bị hủy';
        body = `Đơn hàng #${orderId} đã bị hủy. Xin lỗi vì sự bất tiện này!`;
        break;

      default:
        title = '📱 Cập nhật đơn hàng';
        body = `Đơn hàng #${orderId} có cập nhật mới`;
    }

    return {
      title,
      body,
      data: {
        type: 'order_status_update',
        orderId: orderId.toString(),
        status,
        restaurantName: restaurantName || '',
        timestamp: new Date().toISOString(),
      },
    };
  }
}
