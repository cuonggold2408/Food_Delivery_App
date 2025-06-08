import { createZodDto } from '@anatine/zod-nestjs';
import { OrderSchema } from 'src/routes/order/order.model';

export class CreateOrderDTO extends createZodDto(OrderSchema) {}
