import { z } from 'zod';

export const CartSchema = z.object({
  cart_id: z.number(),
  user_id: z.number(),
  restaurant_id: z.string(),
  created_at: z.date(),
  updated_at: z.date(),
});

export type CartType = z.infer<typeof CartSchema>;

export const CartItemSchema = z.object({
  cart_item_id: z.string(),
  cart_id: z.string(),
  item_id: z.string(),
  total_pay: z.string(),
  quantity: z.number(),
  message: z.string().optional(),
  created_at: z.date(),
  updated_at: z.date(),
});

export type CartItemType = z.infer<typeof CartItemSchema>;

export const CartItemCustomSchema = z.object({
  cart_item_id: z.number(),
  option_id: z.number(),
});

export type CartItemCustomType = z.infer<typeof CartItemCustomSchema>;

export const CartBodySchema = CartSchema.pick({
  user_id: true,
  restaurant_id: true,
}).extend({
  item_id: CartItemSchema.shape.item_id,
  total_pay: CartItemSchema.shape.total_pay,
  quantity: CartItemSchema.shape.quantity,
  message: CartItemSchema.shape.message.optional(),
  customizations: CartItemCustomSchema.array().optional(),
});

export type CartBodyType = z.infer<typeof CartBodySchema>;

export const CartItemBodySchema = CartItemSchema.pick({
  item_id: true,
  total_pay: true,
  quantity: true,
  message: true,
}).extend({
  customizations: CartItemCustomSchema.array().optional(),
});

export type CartItemBodyType = z.infer<typeof CartItemBodySchema>;
