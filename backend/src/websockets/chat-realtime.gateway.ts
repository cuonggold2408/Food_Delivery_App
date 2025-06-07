import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Injectable } from '@nestjs/common';
import { ChatService } from 'src/routes/chat/chat.service';
import { SendMessageDTO } from 'src/routes/chat/chat.dto';
import { generateRoomUserId } from 'src/shared/helpers';

@Injectable()
@WebSocketGateway({
  namespace: 'chat-realtime',
  cors: {
    origin: '*',
  },
})
export class ChatRealtimeGateway
  implements OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer()
  server: Server;

  private connectedUsers = new Map<number, Set<string>>(); // Track user connections

  constructor(private readonly chatService: ChatService) {}

  async handleConnection(client: Socket) {
    console.log(`Chat client connected: ${client.id}`);

    const userId = (client as any).userId;
    if (userId) {
      // Track connections per user
      if (!this.connectedUsers.has(userId)) {
        this.connectedUsers.set(userId, new Set());
      }
      this.connectedUsers.get(userId)!.add(client.id);

      const userRoom = generateRoomUserId(userId);
      await client.join(userRoom);
      console.log(
        `User ${userId} joined room: ${userRoom} (${this.connectedUsers.get(userId)!.size} connections)`,
      );
    }
  }

  async handleDisconnect(client: Socket) {
    console.log(`Chat client disconnected: ${client.id}`);

    const userId = (client as any).userId;
    if (userId && this.connectedUsers.has(userId)) {
      this.connectedUsers.get(userId)!.delete(client.id);
      if (this.connectedUsers.get(userId)!.size === 0) {
        this.connectedUsers.delete(userId);
      }
    }
  }

  @SubscribeMessage('join-chat')
  async handleJoinChat(
    @MessageBody() data: { chat_id: number },
    @ConnectedSocket() client: Socket,
  ) {
    const chatRoom = `chat-${data.chat_id}`;

    // Check if already in room
    if (client.rooms.has(chatRoom)) {
      console.log(`Client ${client.id} already in room ${chatRoom}`);
      return;
    }

    await client.join(chatRoom);
    console.log(`Client ${client.id} joined room: ${chatRoom}`);

    client.emit('joined-chat', {
      chat_id: data.chat_id,
      message: 'Đã tham gia chat',
    });
  }

  @SubscribeMessage('send-message')
  async handleSendMessage(
    @MessageBody()
    data: SendMessageDTO & { sender_id: number; sender_type: 'user' | 'admin' },
    @ConnectedSocket() client: Socket,
  ) {
    console.log(`=== SEND MESSAGE ===`);
    console.log(`Sender: ${data.sender_id} (${data.sender_type})`);
    console.log(`Client: ${client.id}`);
    console.log(`Rooms: ${Array.from(client.rooms).join(', ')}`);

    try {
      let message;

      if (data.sender_type === 'admin') {
        message = await this.chatService.adminSendMessage(data, data.sender_id);
      } else {
        message = await this.chatService.sendMessage(data, data.sender_id);
      }

      const chatRoom = `chat-${data.chat_id}`;

      // Fetch all clients in the chat room
      const roomClients = await this.server.in(chatRoom).fetchSockets();
      console.log(`Room ${chatRoom} has ${roomClients.length} clients`);

      // Emit to other clients in the room (excluding the sender)
      roomClients.forEach((socket) => {
        // Don't emit to the sender
        if (socket.id !== client.id) {
          socket.emit('new-message', {
            message,
            chat_id: data.chat_id,
          });
        }
      });

      console.log(`Message emitted to room ${chatRoom}`);

      // Emit a confirmation to the sender
      client.emit('message-sent', { success: true, message });
    } catch (error) {
      console.error('Send message error:', error);
      client.emit('message-error', {
        success: false,
        error: error.message,
      });
    }
  }

  @SubscribeMessage('typing')
  async handleTyping(
    @MessageBody()
    data: { chat_id: number; user_id: number; is_typing: boolean },
    @ConnectedSocket() client: Socket,
  ) {
    const chatRoom = `chat-${data.chat_id}`;
    client.to(chatRoom).emit('user-typing', {
      chat_id: data.chat_id,
      user_id: data.user_id,
      is_typing: data.is_typing,
    });
  }

  // Notification methods for external use
  async notifyNewChat(chat: any) {
    // Notify all admin users about new chat
    this.server.emit('new-chat-created', {
      type: 'new_chat',
      chat,
      message: `Chat mới từ ${chat.user.name}`,
    });
  }

  async notifyChatStatusUpdate(chatId: number, status: string, userId: number) {
    const userRoom = generateRoomUserId(userId);
    this.server.to(userRoom).emit('chat-status-updated', {
      type: 'status_update',
      chat_id: chatId,
      status,
      message: `Trạng thái chat đã được cập nhật: ${status}`,
    });
  }
}
