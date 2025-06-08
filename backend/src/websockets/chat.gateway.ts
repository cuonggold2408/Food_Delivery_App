import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server } from 'socket.io';

@WebSocketGateway({ namespace: 'chat' })
export class ChatGateway {
  @WebSocketServer()
  server: Server;

  @SubscribeMessage('send-message')
  handleMessage(@MessageBody() data: string): string {
    this.server.emit('receive-message', {
      data: `Message received: ${data}`,
    });
    return data;
  }
}
