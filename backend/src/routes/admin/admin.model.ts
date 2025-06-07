import { z } from 'zod';

export const AddRestaurantBodySchema = z.object({
  name: z.string(),
  city: z.string(),
  is_active: z.boolean().default(true).optional(),
  shop_image_url: z.string(),
  latitude: z.number(),
  longitude: z.number(),
  rating: z.number().default(0),
  restaurant_id: z.string(),
});

export type AddRestaurantBodyType = z.infer<typeof AddRestaurantBodySchema>;

export const AddFoodBodySchema = z.object({
  name: z.string(),
  description: z.string().optional(),
  price: z.string(),
  image_url: z.string(),
});

export type AddFoodBodyType = z.infer<typeof AddFoodBodySchema>;

export const AddFoodCategoryBodySchema = z.object({
  name: z.string(),
});

export type AddFoodCategoryBodyType = z.infer<typeof AddFoodCategoryBodySchema>;

export const CreateDiscountCodeBodySchema = z.object({
  title: z.string(),
  description: z.string(),
  promo_code: z.string(),
  discount_type: z.string(),
  discount_value: z.number(),
  min_order_value: z.number(),
  max_discount_amount: z.number(),
  end_date: z.number(),
  usage_limit: z.number(),
  is_active: z.boolean().default(true),
});

export type CreateDiscountCodeBodyType = z.infer<
  typeof CreateDiscountCodeBodySchema
>;
