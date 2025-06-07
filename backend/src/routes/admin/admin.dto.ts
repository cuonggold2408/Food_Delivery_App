import { createZodDto } from '@anatine/zod-nestjs';
import { AddRestaurantBodySchema } from 'src/routes/admin/admin.model';

export class AddRestaurantBodyDTO extends createZodDto(
  AddRestaurantBodySchema,
) {}
