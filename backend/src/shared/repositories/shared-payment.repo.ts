import { Injectable } from '@nestjs/common';
import { InjectEntityManager, InjectRepository } from '@nestjs/typeorm';
import { Order, OrderStatus } from 'src/database/entities/order/order.entity';
import { Payment } from 'src/database/entities/payment/payment.entity';
import { PaymentStatus } from 'src/shared/constants/payment.constant';
import { EntityManager, In, Repository } from 'typeorm';

@Injectable()
export class SharedPaymentRepository {
  constructor(
    @InjectRepository(Payment)
    private readonly paymentRepository: Repository<Payment>,

    @InjectEntityManager()
    private readonly entityManager: EntityManager,
  ) {}

  async cancelPaymentAndOrder(paymentId: number) {
    const payment = await this.paymentRepository.findOne({
      where: {
        payment_id: paymentId,
      },
      relations: ['orders'],
    });

    if (!payment) {
      throw Error('Payment not found');
    }

    const { orders } = payment;

    await this.entityManager.transaction(async (tx) => {
      await tx.update(
        Order,
        {
          order_id: In(orders.map((order) => order.order_id)),
          order_status: OrderStatus.PENDING_PAYMENT,
        },
        {
          order_status: OrderStatus.CANCELLED,
        },
      );
      await tx.update(
        Payment,
        {
          payment_id: paymentId,
        },
        {
          payment_status: PaymentStatus.FAILED,
        },
      );
    });
  }
}
