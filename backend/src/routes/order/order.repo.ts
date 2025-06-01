import {
  Injectable,
  UnauthorizedException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { CartItem } from 'src/database/entities/cart/cart-item.entity';
import { Cart } from 'src/database/entities/cart/cart.entity';
import { Order, OrderStatus } from 'src/database/entities/order/order.entity';
import { Payment } from 'src/database/entities/payment/payment.entity';
import { CreateOrderDTO } from 'src/routes/order/order.dto';
import { OrderProducer } from 'src/routes/order/order.producer';
import envConfig from 'src/shared/config';
import { DeepPartial, Repository } from 'typeorm';

@Injectable()
export class OrderRepository {
  constructor(
    @InjectRepository(Order)
    private readonly orderRepository: Repository<Order>,

    @InjectRepository(Payment)
    private readonly paymentRepository: Repository<Payment>,

    @InjectRepository(Cart)
    private readonly cartRepository: Repository<Cart>,

    @InjectRepository(CartItem)
    private readonly cartItemRepository: Repository<CartItem>,

    private readonly orderProducer: OrderProducer,
  ) {}

  async createOrder(body: CreateOrderDTO, userId: number) {
    if (!userId) {
      throw new UnauthorizedException('Unauthorized');
    }

    const orderExist = await this.orderRepository.find({
      where: {
        user: { user_id: userId },
        restaurant: { restaurant_id: body.restaurant_id.toString() },
      },
    });

    if (
      orderExist.length > 0 &&
      orderExist[orderExist.length - 1]?.order_status ===
        OrderStatus.PENDING_PAYMENT
    ) {
      throw new BadRequestException(
        'You already have a pending payment order. Please complete or cancel it before creating a new order.',
      );
    }

    const cartId = await this.cartRepository.findOne({
      where: {
        user: { user_id: userId },
        restaurant: { restaurant_id: body.restaurant_id.toString() },
      },
    });

    const cartItems = await this.cartItemRepository.find({
      where: {
        cart: { cart_id: cartId?.cart_id },
      },
      relations: [
        'menuItem',
        'menuItem.customizationMappings',
        'menuItem.customizationMappings.category',
      ],
    });

    const items = cartItems.map((item) => ({
      quantity: item.quantity,
      total_pay: item.total_pay,
      message: item.message,
      dish: {
        name: item.menuItem.name,
        image: item.menuItem.image_url,
        price: item.menuItem.price,
        options: item.menuItem.customizationMappings.map((option) => ({
          name: option.category.name,
        })),
      },
    }));

    const newPayment = this.paymentRepository.create();
    await this.paymentRepository.save(newPayment);
    await this.orderProducer.addCancelPaymentJob(newPayment.payment_id);

    const orderData = {
      user: { user_id: userId },
      restaurant: { restaurant_id: body.restaurant_id.toString() },
      payment: { payment_id: newPayment.payment_id },
      receiver: body.receiver,
      items: items,
      subtotal: body.subtotal,
      delivery_fee: body.delivery_fee,
      discount: body.discount || '0',
      total_amount: (
        Number(body.subtotal) +
        Number(body.delivery_fee) -
        Number(body.discount || '0')
      ).toString(),
      payment_method: body.payment_method,
      // estimated_delivery_time: body?.estimated_delivery_time,
      delivery_method: body.delivery_method,
    };

    const order = this.orderRepository.create(
      orderData as unknown as DeepPartial<Order>,
    );
    await this.orderRepository.save(order);

    await this.cartRepository.delete({
      user: { user_id: userId },
      restaurant: { restaurant_id: body.restaurant_id.toString() },
    });

    const qrLink = `https://qr.sepay.vn/img?acc=${envConfig.ACC_BANK}&bank=${envConfig.SHORT_BANK}&amount=${order.total_amount}&des=DH${order.payment.payment_id}`;

    return {
      qr_link: qrLink,
      time_out: new Date(Date.now() + 1000 * 60 * 10),
    };
  }
}
