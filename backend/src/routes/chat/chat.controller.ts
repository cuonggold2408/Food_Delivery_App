import {
  Controller,
  Post,
  Get,
  Patch,
  Body,
  Param,
  Query,
  Req,
  ParseIntPipe,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiResponse,
} from '@nestjs/swagger';
import { ChatService } from './chat.service';
import { CreateChatDTO, SendMessageDTO, GetChatsQueryDTO } from './chat.dto';
import { ChatStatus } from 'src/database/entities/chat/chat.entity';

@ApiTags('Chat')
@Controller('chat')
@ApiBearerAuth()
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  // ===== USER ENDPOINTS =====
  @Post()
  @ApiOperation({ summary: 'User tạo chat mới' })
  @ApiResponse({ status: 201, description: 'Chat được tạo thành công' })
  async findOrCreateChat(@Body() body: CreateChatDTO, @Req() req: any) {
    const userId = req.user.user_id;
    return this.chatService.findOrCreateChat(body, userId);
  }

  @Post('message')
  @ApiOperation({ summary: 'User gửi tin nhắn' })
  @ApiResponse({ status: 201, description: 'Tin nhắn được gửi thành công' })
  async sendMessage(@Body() body: SendMessageDTO, @Req() req: any) {
    const userId = req.user.user_id;
    return this.chatService.sendMessage(body, userId);
  }

  @Get()
  @ApiOperation({ summary: 'User xem danh sách chat của mình' })
  @ApiResponse({ status: 200, description: 'Danh sách chat' })
  async getUserChats(@Query() query: GetChatsQueryDTO, @Req() req: any) {
    const userId = req.user.user_id;
    return this.chatService.getUserChats(userId, query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Xem chi tiết chat' })
  @ApiResponse({ status: 200, description: 'Chi tiết chat' })
  async getChatDetail(
    @Param('id', ParseIntPipe) chatId: number,
    @Req() req: any,
  ) {
    const userId = req.user.user_id;
    const isAdmin = req.user.user_role === 'admin';
    return this.chatService.getChatDetail(chatId, userId, isAdmin);
  }

  @Get(':id/messages')
  @ApiOperation({ summary: 'Xem tin nhắn của chat' })
  @ApiResponse({ status: 200, description: 'Danh sách tin nhắn' })
  async getChatMessages(
    @Param('id', ParseIntPipe) chatId: number,
    @Query('page') page: string = '1',
    @Req() req: any,
  ) {
    const userId = req.user.user_id;
    const isAdmin = req.user.user_role === 'admin';
    return this.chatService.getChatMessages(
      chatId,
      userId,
      isAdmin,
      parseInt(page),
    );
  }

  // ===== ADMIN ENDPOINTS =====
  @Get('admin/list')
  @ApiOperation({
    summary: 'Admin xem tất cả chat',
    description: 'Admin xem tất cả chat từ users để phản hồi',
  })
  @ApiResponse({ status: 200, description: 'Danh sách tất cả chat' })
  async getAllChats(@Query() query: GetChatsQueryDTO) {
    return this.chatService.getAdminChats(query);
  }

  @Post('admin/:id/reply')
  @ApiOperation({
    summary: 'Admin phản hồi tin nhắn',
    description: 'Admin gửi tin nhắn phản hồi user trong chat',
  })
  @ApiResponse({ status: 201, description: 'Tin nhắn được gửi thành công' })
  async adminReply(
    @Param('id', ParseIntPipe) chatId: number,
    @Body() body: Omit<SendMessageDTO, 'chat_id'>,
    @Req() req: any,
  ) {
    const adminId = req.user.user_id;
    const messageData = { ...body, chat_id: chatId };
    return this.chatService.adminSendMessage(messageData, adminId);
  }

  @Patch('admin/:id/close')
  @ApiOperation({
    summary: 'Admin đóng chat',
    description: 'Đóng chat khi đã xử lý xong vấn đề của user',
  })
  @ApiResponse({ status: 200, description: 'Chat đã được đóng' })
  async closeChat(@Param('id', ParseIntPipe) chatId: number) {
    return this.chatService.updateChatStatus(chatId, ChatStatus.CLOSED);
  }

  @Patch('admin/:id/activate')
  @ApiOperation({
    summary: 'Admin kích hoạt chat',
    description: 'Chuyển chat từ pending sang active để bắt đầu hỗ trợ',
  })
  @ApiResponse({ status: 200, description: 'Chat đã được kích hoạt' })
  async activateChat(@Param('id', ParseIntPipe) chatId: number) {
    return this.chatService.updateChatStatus(chatId, ChatStatus.ACTIVE);
  }
}
