import { BadRequestException, Injectable } from '@nestjs/common';
import { InjectEntityManager, InjectRepository } from '@nestjs/typeorm';
import { parse } from 'date-fns';
import { PaymentTransaction } from 'src/database/entities/payment/payment-transaction.entity';
import { Payment } from 'src/database/entities/payment/payment.entity';
import { WebhookPaymentBodyType } from 'src/routes/payment/payment.model';
import {
  PaymentStatus,
  PREFIX_PAYMENT_CODE,
} from 'src/shared/constants/payment.constant';
import { In, Repository } from 'typeorm';
import { EntityManager } from 'typeorm';
import { Order, OrderStatus } from 'src/database/entities/order/order.entity';
import { PaymentProducer } from 'src/routes/payment/payment.producer';

@Injectable()
export class PaymentRepository {
  constructor(
    @InjectRepository(PaymentTransaction)
    private readonly paymentTransactionRepository: Repository<PaymentTransaction>,

    @InjectRepository(Payment)
    private readonly paymentRepository: Repository<Payment>,

    @InjectEntityManager()
    private readonly entityManager: EntityManager,

    private readonly paymentProducer: PaymentProducer,
  ) {}

  async receiver(body: WebhookPaymentBodyType) {
    // 1. Thêm thông tin giao dịch vào DB
    let amount_in = 0;
    let amount_out = 0;

    if (body.transferType === 'in') {
      amount_in = body.transferAmount;
    } else if (body.transferType === 'out') {
      amount_out = body.transferAmount;
    }

    const uniquePaymentTransaction =
      await this.paymentTransactionRepository.findOne({
        where: {
          id: body.id,
        },
      });

    if (uniquePaymentTransaction) {
      throw new BadRequestException('Payment transaction already exists');
    }
    await this.entityManager.transaction(async (transactionalEntityManager) => {
      const paymentTransaction = new PaymentTransaction();
      paymentTransaction.id = body.id;
      paymentTransaction.gateway = body.gateway;
      paymentTransaction.transaction_date = parse(
        body.transactionDate,
        'yyyy-MM-dd HH:mm:ss',
        new Date(),
      );
      paymentTransaction.account_number = body.accountNumber?.toString() ?? '';
      paymentTransaction.sub_account = body.subAccount?.toString() ?? '';
      paymentTransaction.amount_in = amount_in.toString();
      paymentTransaction.amount_out = amount_out.toString();
      paymentTransaction.accumulated = body.accumulated.toString();
      paymentTransaction.code = body.code?.toString() ?? '';
      paymentTransaction.transaction_content = body.content?.toString() ?? '';
      paymentTransaction.reference_number =
        body.referenceCode?.toString() ?? '';
      paymentTransaction.body = body.description;

      console.log('paymentTransaction: ', paymentTransaction);

      // Lưu vào database
      await this.paymentTransactionRepository.save(paymentTransaction);

      // 2. Kiểm tra nội dung chuyển khoản và tổng số tiền có khớp hay không
      const paymentId = body.code
        ? Number(body.code.split(PREFIX_PAYMENT_CODE)[1])
        : Number(body.content?.split(PREFIX_PAYMENT_CODE)[1]);

      if (isNaN(paymentId)) {
        throw new BadRequestException('Cannot get payment id from content');
      }

      const payment = await transactionalEntityManager.findOne(Payment, {
        where: {
          payment_id: paymentId,
        },
        relations: ['orders'],
      });

      if (!payment) {
        throw new BadRequestException(
          'Cannot find payment with id: ' + paymentId,
        );
      }

      const { orders } = payment;

      // 3. Kiểm tra tổng số tiền có khớp hay không
      const totalAmount = Number(
        orders.reduce((acc, order) => acc + Number(order.total_amount), 0),
      );

      if (totalAmount !== body.transferAmount) {
        throw new BadRequestException('Tổng số tiền không khớp');
      }

      // 4. Cập nhật trạng thái thanh toán
      // Cập nhật Payment
      await transactionalEntityManager.update(
        Payment,
        {
          payment_id: paymentId,
        },
        {
          payment_status: PaymentStatus.SUCCESS,
        },
      );

      // Cập nhật tất cả Order liên quan
      await transactionalEntityManager.update(
        Order,
        { order_id: In(orders.map((order) => order.order_id)) },
        { order_status: OrderStatus.PENDING_PICKUP },
      );

      await this.paymentProducer.removeJob(paymentId);
    });

    return {
      message: 'Payment successful',
    };
  }
}
