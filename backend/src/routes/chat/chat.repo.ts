import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Chat, ChatStatus } from 'src/database/entities/chat/chat.entity';
import {
  Message,
  SenderType,
  MessageType,
} from 'src/database/entities/chat/message.entity';
import {
  CreateChatType,
  SendMessageType,
  GetChatsQueryType,
} from './chat.model';

@Injectable()
export class ChatRepository {
  constructor(
    @InjectRepository(Chat)
    private readonly chatRepository: Repository<Chat>,
    @InjectRepository(Message)
    private readonly messageRepository: Repository<Message>,
  ) {}

  // Tìm hoặc tạo chat mới
  async findOrCreateChat(data: CreateChatType, userId: number) {
    const existingChat = await this.chatRepository.findOne({
      where: {
        user_id: userId,
        subject: data.subject,
      },
    });

    if (existingChat) {
      return this.getChatById(existingChat.chat_id);
    }

    const chat = this.chatRepository.create({
      user_id: userId,
      subject: data.subject,
      status: ChatStatus.PENDING,
      admin_id: 1,
      last_message_at: new Date(),
    });

    const savedChat = await this.chatRepository.save(chat);

    // Tạo tin nhắn đầu tiên
    const initialMessage = this.messageRepository.create({
      chat_id: savedChat.chat_id,
      sender_id: userId,
      sender_type: SenderType.USER,
      message_type: MessageType.TEXT,
      content: data.initial_message,
    });

    await this.messageRepository.save(initialMessage);

    return this.getChatById(savedChat.chat_id);
  }

  // Gửi tin nhắn
  async sendMessage(
    data: SendMessageType,
    senderId: number,
    senderType: SenderType,
  ) {
    const message = this.messageRepository.create({
      chat_id: data.chat_id,
      sender_id: senderId,
      sender_type: senderType,
      message_type: data.message_type as MessageType,
      content: data.content,
      attachment_url: data.attachment_url,
    });

    await this.messageRepository.save(message);

    // Cập nhật last_message_at cho chat
    await this.chatRepository.update(data.chat_id, {
      last_message_at: new Date(),
    });

    return message;
  }

  // Lấy danh sách chat của user
  async getUserChats(userId: number, query: GetChatsQueryType) {
    const { page, limit, status } = query;
    const skip = (page - 1) * limit;

    const queryBuilder = this.chatRepository
      .createQueryBuilder('chat')
      .leftJoinAndSelect('chat.user', 'user')
      .leftJoinAndSelect('chat.admin', 'admin')
      .leftJoinAndSelect('chat.messages', 'messages')
      .where('chat.user_id = :userId', { userId })
      .orderBy('chat.last_message_at', 'DESC')
      .skip(skip)
      .take(limit);

    if (status) {
      queryBuilder.andWhere('chat.status = :status', { status });
    }

    const [chats, total] = await queryBuilder.getManyAndCount();

    return {
      chats,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  // Lấy danh sách chat cho admin
  async getAdminChats(query: GetChatsQueryType) {
    const { page, limit, status } = query;
    const skip = (page - 1) * limit;

    const queryBuilder = this.chatRepository
      .createQueryBuilder('chat')
      .leftJoinAndSelect('chat.user', 'user')
      .leftJoinAndSelect('chat.admin', 'admin')
      .leftJoinAndSelect('chat.messages', 'messages')
      .orderBy('chat.last_message_at', 'DESC')
      .skip(skip)
      .take(limit);

    if (status) {
      queryBuilder.andWhere('chat.status = :status', { status });
    }

    const [chats, total] = await queryBuilder.getManyAndCount();

    return {
      chats,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  // Lấy chi tiết chat
  async getChatById(chatId: number) {
    return this.chatRepository
      .createQueryBuilder('chat')
      .leftJoinAndSelect('chat.user', 'user')
      .leftJoinAndSelect('chat.admin', 'admin')
      .leftJoinAndSelect('chat.messages', 'messages')
      .leftJoinAndSelect('messages.sender', 'sender')
      .where('chat.chat_id = :chatId', { chatId })
      .orderBy('messages.created_at', 'ASC')
      .getOne();
  }

  // Cập nhật trạng thái chat
  async updateChatStatus(chatId: number, status: ChatStatus) {
    await this.chatRepository.update(chatId, { status });
    return this.getChatById(chatId);
  }

  // Đánh dấu tin nhắn đã đọc
  async markMessagesAsRead(chatId: number, userId: number) {
    await this.messageRepository
      .createQueryBuilder()
      .update(Message)
      .set({ is_read: true, read_at: new Date() })
      .where('chat_id = :chatId', { chatId })
      .andWhere('sender_id != :userId', { userId })
      .andWhere('is_read = false')
      .execute();
  }

  // Lấy tin nhắn của chat
  async getChatMessages(chatId: number, page: number = 1, limit: number = 50) {
    const skip = (page - 1) * limit;

    const [messages, total] = await this.messageRepository
      .createQueryBuilder('message')
      .leftJoinAndSelect('message.sender', 'sender')
      .where('message.chat_id = :chatId', { chatId })
      .orderBy('message.created_at', 'DESC')
      .skip(skip)
      .take(limit)
      .getManyAndCount();

    return {
      messages: messages.reverse(), // Đảo ngược để tin nhắn cũ ở trên
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }
}
