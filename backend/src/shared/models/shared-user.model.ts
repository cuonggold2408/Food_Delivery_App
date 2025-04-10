import { z } from 'zod';

export enum UserRole {
  CUSTOMER = 'customer',
  ADMIN = 'admin',
}

export const UserSchema = z.object({
  user_id: z.number(),
  email: z.string().email(),
  password: z.string().min(8).max(100),
  name: z.string().min(1).max(100),
  user_role: z.nativeEnum(UserRole),
  created_at: z.date(),
  updated_at: z.date(),
});

export type UserType = z.infer<typeof UserSchema>;

export const AuthProviderSchema = z.object({
  auth_id: z.number(),
  user_id: z.number(),
  provider_name: z.string(),
  provider_user_id: z.string(),
  refresh_token: z.string(),
  expired_at: z.date(),
  created_at: z.date(),
  updated_at: z.date(),
});
export type AuthProviderType = z.infer<typeof AuthProviderSchema>;
