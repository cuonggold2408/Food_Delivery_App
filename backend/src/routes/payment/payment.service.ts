import { Injectable } from '@nestjs/common';
import { WebSocketGateway, WebSocketServer } from '@nestjs/websockets';
import { Server } from 'socket.io';
import { WebhookPaymentBodyDTO } from 'src/routes/payment/payment.dto';
import { PaymentRepository } from 'src/routes/payment/payment.repo';
import { generateRoomUserId } from 'src/shared/helpers';
import { SharedWebSocketRepository } from 'src/shared/repositories/shared-websocket.repo';

@Injectable()
@WebSocketGateway({ namespace: 'payment' })
export class PaymentService {
  @WebSocketServer()
  server: Server;
  constructor(
    private readonly paymentRepository: PaymentRepository,
    private readonly sharedWebSocketRepository: SharedWebSocketRepository,
  ) {}

  async receiver(body: WebhookPaymentBodyDTO) {
    const userId = await this.paymentRepository.receiver(body);
    this.server.to(generateRoomUserId(userId)).emit('payment', {
      status: 'success',
    });
    // try {
    //   const websockets =
    //     await this.sharedWebSocketRepository.findManyByUserId(userId);
    //   websockets.forEach((websocket) => {
    //     this.server.to(websocket.socket_id).emit('payment', {
    //       status: 'success',
    //     });
    //   });
    // } catch (error) {
    //   console.log('error: ', error);
    // }
    return {
      message: 'Payment received successfully',
    };
  }
}
