import { Module } from '@nestjs/common';
import { PaymentController } from './payment.controller';
import { PaymentService } from './payment.service';
import { PaymentRepository } from 'src/routes/payment/payment.repo';
import { PaymentTransaction } from 'src/database/entities/payment/payment-transaction.entity';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Payment } from 'src/database/entities/payment/payment.entity';

@Module({
  imports: [TypeOrmModule.forFeature([PaymentTransaction, Payment])],
  controllers: [PaymentController],
  providers: [PaymentService, PaymentRepository],
})
export class PaymentModule {}
