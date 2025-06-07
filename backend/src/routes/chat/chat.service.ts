import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { ChatRepository } from './chat.repo';
import {
  CreateChatType,
  SendMessageType,
  GetChatsQueryType,
} from './chat.model';
import { ChatStatus } from 'src/database/entities/chat/chat.entity';
import { SenderType } from 'src/database/entities/chat/message.entity';

@Injectable()
export class ChatService {
  constructor(private readonly chatRepository: ChatRepository) {}

  // User tạo chat mới
  async createChat(data: CreateChatType, userId: number) {
    return this.chatRepository.createChat(data, userId);
  }

  // User gửi tin nhắn
  async sendMessage(data: SendMessageType, userId: number) {
    const chat = await this.chatRepository.getChatById(data.chat_id);

    if (!chat) {
      throw new NotFoundException('Chat không tồn tại');
    }

    if (chat.user_id !== userId) {
      throw new ForbiddenException(
        'Bạn không có quyền gửi tin nhắn trong chat này',
      );
    }

    return this.chatRepository.sendMessage(data, userId, SenderType.USER);
  }

  async adminSendMessage(data: SendMessageType, adminId: number) {
    const chat = await this.chatRepository.getChatById(data.chat_id);

    if (!chat) {
      throw new NotFoundException('Chat không tồn tại');
    }

    return this.chatRepository.sendMessage(data, adminId, SenderType.ADMIN);
  }

  // Lấy danh sách chat của user
  async getUserChats(userId: number, query: GetChatsQueryType) {
    return this.chatRepository.getUserChats(userId, query);
  }

  // Admin xem tất cả chat
  async getAdminChats(query: GetChatsQueryType) {
    return this.chatRepository.getAdminChats(query);
  }

  // Xem chi tiết chat
  async getChatDetail(
    chatId: number,
    userId: number,
    isAdmin: boolean = false,
  ) {
    const chat = await this.chatRepository.getChatById(chatId);

    if (!chat) {
      throw new NotFoundException('Chat không tồn tại');
    }

    if (!isAdmin && chat.user_id !== userId) {
      throw new ForbiddenException('Bạn không có quyền xem chat này');
    }

    // Đánh dấu tin nhắn đã đọc
    await this.chatRepository.markMessagesAsRead(chatId, userId);

    return chat;
  }

  // Cập nhật trạng thái chat
  async updateChatStatus(chatId: number, status: ChatStatus) {
    const chat = await this.chatRepository.getChatById(chatId);

    if (!chat) {
      throw new NotFoundException('Chat không tồn tại');
    }

    return this.chatRepository.updateChatStatus(chatId, status);
  }

  // Lấy tin nhắn của chat
  async getChatMessages(
    chatId: number,
    userId: number,
    isAdmin: boolean = false,
    page: number = 1,
  ) {
    const chat = await this.chatRepository.getChatById(chatId);

    if (!chat) {
      throw new NotFoundException('Chat không tồn tại');
    }

    if (!isAdmin && chat.user_id !== userId) {
      throw new ForbiddenException('Bạn không có quyền xem tin nhắn này');
    }

    return this.chatRepository.getChatMessages(chatId, page);
  }
}
