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
