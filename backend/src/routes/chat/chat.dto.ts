import { createZodDto } from '@anatine/zod-nestjs';
import {
  CreateChatSchema,
  SendMessageSchema,
  GetChatsQuerySchema,
  UpdateChatStatusSchema,
} from './chat.model';

export class CreateChatDTO extends createZodDto(CreateChatSchema) {}
export class SendMessageDTO extends createZodDto(SendMessageSchema) {}
export class GetChatsQueryDTO extends createZodDto(GetChatsQuerySchema) {}
export class UpdateChatStatusDTO extends createZodDto(UpdateChatStatusSchema) {}
