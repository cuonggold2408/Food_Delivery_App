import { Injectable } from '@nestjs/common';
import { WebhookPaymentBodyDTO } from 'src/routes/payment/payment.dto';
import { PaymentRepository } from 'src/routes/payment/payment.repo';

@Injectable()
export class PaymentService {
  constructor(private readonly paymentRepository: PaymentRepository) {}

  async receiver(body: WebhookPaymentBodyDTO) {
    const result = await this.paymentRepository.receiver(body);

    return result;
  }
}
