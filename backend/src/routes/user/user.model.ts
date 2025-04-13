import { UserAddressSchema } from 'src/shared/models/shared-user.model';
import { z } from 'zod';

export const UserAddressBodySchema = UserAddressSchema.pick({
  user_id: true,
  address_name: true,
  phone_number: true,
  recipient_name: true,
  street_address: true,
  postal_code: true,
  apartment: true,
  is_default: true,
  latitude: true,
  longitude: true,
}).strict();
export type UserAddressBodyType = z.infer<typeof UserAddressBodySchema>;
