import {
  DeliveryMethod,
  PaymentMethod,
} from 'src/database/entities/order/order.entity';
import { z } from 'zod';

export const OrderSchema = z
  .object({
    receiver: z.object({
      name: z.string(),
      phone: z.string(),
      address: z.string(),
    }),
    subtotal: z.string(),
    delivery_fee: z.string(),
    discount: z.string().nullable(),
    payment_method: z
      .nativeEnum(PaymentMethod)
      .default(PaymentMethod.BANK_TRANSFER),
    // estimated_delivery_time: z.date().nullable(),
    delivery_method: z
      .nativeEnum(DeliveryMethod)
      .default(DeliveryMethod.STANDARD),
    created_at: z.date(),
    updated_at: z.date(),
  })
  .extend({
    restaurant_id: z.string(),
  });

export type OrderType = z.infer<typeof OrderSchema>;
