import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ChatController } from './chat.controller';
import { ChatService } from './chat.service';
import { ChatRepository } from './chat.repo';
import { Chat } from 'src/database/entities/chat/chat.entity';
import { Message } from 'src/database/entities/chat/message.entity';
import { ChatRealtimeGateway } from 'src/websockets/chat-realtime.gateway';

@Module({
  imports: [TypeOrmModule.forFeature([Chat, Message])],
  controllers: [ChatController],
  providers: [ChatService, ChatRepository, ChatRealtimeGateway],
  exports: [ChatService, ChatRealtimeGateway],
})
export class ChatModule {}
