import { createZodDto } from '@anatine/zod-nestjs';
import { WebhookPaymentBodySchema } from 'src/routes/payment/payment.model';

export class WebhookPaymentBodyDTO extends createZodDto(
  WebhookPaymentBodySchema,
) {}
