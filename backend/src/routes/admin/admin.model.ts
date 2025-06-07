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
