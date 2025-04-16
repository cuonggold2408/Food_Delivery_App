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

export const UserAddressSchema = z.object({
  address_id: z.number(),
  user_id: z.number(),
  address_name: z.string().max(100),
  phone_number: z.string().max(20),
  recipient_name: z.string().max(100),
  street_address: z.string().max(255),
  postal_code: z.string().max(20),
  apartment: z.string().max(100).optional(),
  is_default: z.boolean().default(false),
  latitude: z.number(),
  longitude: z.number(),
  created_at: z.date(),
  updated_at: z.date(),
});
export type UserAddressType = z.infer<typeof UserAddressSchema>;

export const UserProfileSchema = z.object({
  user_id: z.number(),
  name: z.string().min(1).max(100),
  email: z.string().email(),
  phone_number: z.string().max(20).default(''),
  bio: z.string().max(255).optional(),
});
export type UserProfileType = z.infer<typeof UserProfileSchema>;
