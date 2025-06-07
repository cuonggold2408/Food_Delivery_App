import { Module } from '@nestjs/common';
import { ChatModule } from 'src/routes/chat/chat.module';
import { ChatRealtimeGateway } from 'src/websockets/chat-realtime.gateway';
import { ChatGateway } from 'src/websockets/chat.gateway';
import { PaymentGateway } from 'src/websockets/payment.gateway';

@Module({
  imports: [ChatModule],
  providers: [ChatGateway, PaymentGateway, ChatRealtimeGateway],
})
export class WebsocketModule {}
