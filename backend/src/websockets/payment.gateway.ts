import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server } from 'socket.io';

@WebSocketGateway({ namespace: 'payment' })
export class PaymentGateway {
  @WebSocketServer()
  server: Server;

  @SubscribeMessage('send-money')
  handleMessage(@MessageBody() data: string): string {
    this.server.emit('receive-money', {
      data: `Money received: ${data}`,
    });
    return data;
  }
}
