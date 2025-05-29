import { Body, Controller, Post } from '@nestjs/common';
import { ApiBody, ApiOperation } from '@nestjs/swagger';
import { WebhookPaymentBodyDTO } from 'src/routes/payment/payment.dto';
import { PaymentService } from 'src/routes/payment/payment.service';
import { Auth } from 'src/shared/decorators/auth.decorator';

@Controller('payment')
export class PaymentController {
  constructor(private readonly paymentService: PaymentService) {}

  @Post('/receiver')
  @ApiOperation({ summary: 'Receiver payment' })
  @ApiBody({
    description: 'Sepay webhook payload',
    schema: {
      type: 'object',
      properties: {
        id: { type: 'number' },
        gateway: { type: 'string' },
        transactionDate: { type: 'string' },
        accountNumber: { type: 'string', nullable: true },
        code: { type: 'string', nullable: true },
        content: { type: 'string', nullable: true },
        transferType: { type: 'string' },
        transferAmount: { type: 'number' },
        accumulated: { type: 'number' },
        subAccount: { type: 'string', nullable: true },
        referenceCode: { type: 'string', nullable: true },
        description: { type: 'string' },
      },
    },
  })
  @Auth(['PaymentAPIKey'])
  async receiver(@Body() body: WebhookPaymentBodyDTO) {
    console.log('🔔 Webhook received at:', new Date().toISOString());
    console.log('🔔 Body:', JSON.stringify(body, null, 2));
    return this.paymentService.receiver(body);
  }
}
