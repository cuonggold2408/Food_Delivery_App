import { Module } from '@nestjs/common';
import { OrderController } from './order.controller';
import { OrderService } from './order.service';
import { OrderRepository } from 'src/routes/order/order.repo';
import { Order } from 'src/database/entities/order/order.entity';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Payment } from 'src/database/entities/payment/payment.entity';
import { Cart } from 'src/database/entities/cart/cart.entity';
import { CartItem } from 'src/database/entities/cart/cart-item.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Order, Payment, Cart, CartItem])],
  controllers: [OrderController],
  providers: [OrderService, OrderRepository],
})
export class OrderModule {}
