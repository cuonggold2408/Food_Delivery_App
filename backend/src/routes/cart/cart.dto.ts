import { createZodDto } from '@anatine/zod-nestjs';
import { CartBodySchema, CartItemBodySchema } from 'src/routes/cart/cart.model';

export class CartBodyDTO extends createZodDto(CartBodySchema) {}

export class CartItemBodyDTO extends createZodDto(CartItemBodySchema) {}
