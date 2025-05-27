import { Module } from '@nestjs/common';
import { PaymentController } from './payment.controller';
import { PaymentService } from './payment.service';
import { PaymentRepository } from 'src/routes/payment/payment.repo';
import { PaymentTransaction } from 'src/database/entities/payment/payment-transaction.entity';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Payment } from 'src/database/entities/payment/payment.entity';
import { PaymentProducer } from 'src/routes/payment/payment.producer';
import { BullModule } from '@nestjs/bullmq';
import { PAYMENT_QUEUE_NAME } from 'src/shared/constants/queue.constant';

@Module({
  imports: [
    TypeOrmModule.forFeature([PaymentTransaction, Payment]),
    BullModule.registerQueue({
      name: PAYMENT_QUEUE_NAME,
    }),
  ],
  controllers: [PaymentController],
  providers: [PaymentService, PaymentRepository, PaymentProducer],
})
export class PaymentModule {}
