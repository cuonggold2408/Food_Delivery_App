import { z } from 'zod';

export const CreateChatSchema = z.object({
  subject: z.string().min(1).max(255),
  initial_message: z.string().min(1),
});

export const SendMessageSchema = z.object({
  chat_id: z.number(),
  content: z.string().min(1),
  message_type: z.enum(['text', 'image', 'file']).default('text'),
  attachment_url: z.string().url().optional(),
});

export const GetChatsQuerySchema = z.object({
  page: z.string().transform(Number).default('1'),
  limit: z.string().transform(Number).default('10'),
  status: z.enum(['active', 'closed', 'pending']).optional(),
});

export const UpdateChatStatusSchema = z.object({
  status: z.enum(['active', 'closed', 'pending']),
});

export const AssignAdminSchema = z.object({
  admin_id: z.number(),
});

export type CreateChatType = z.infer<typeof CreateChatSchema>;
export type SendMessageType = z.infer<typeof SendMessageSchema>;
export type GetChatsQueryType = z.infer<typeof GetChatsQuerySchema>;
export type UpdateChatStatusType = z.infer<typeof UpdateChatStatusSchema>;
export type AssignAdminType = z.infer<typeof AssignAdminSchema>;
