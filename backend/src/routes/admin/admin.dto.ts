import { createZodDto } from '@anatine/zod-nestjs';
import {
  AddFoodBodySchema,
  AddFoodCategoryBodySchema,
  AddRestaurantBodySchema,
} from 'src/routes/admin/admin.model';

export class AddRestaurantBodyDTO extends createZodDto(
  AddRestaurantBodySchema,
) {}

export class AddFoodBodyDTO extends createZodDto(AddFoodBodySchema) {}

export class AddFoodCategoryBodyDTO extends createZodDto(
  AddFoodCategoryBodySchema,
) {}
