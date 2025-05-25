import { Injectable } from '@nestjs/common';
import { CreateOrderDTO } from 'src/routes/order/order.dto';
import { OrderRepository } from 'src/routes/order/order.repo';

@Injectable()
export class OrderService {
  constructor(private readonly orderRepository: OrderRepository) {}

  async createOrder(body: CreateOrderDTO, userId: number) {
    return this.orderRepository.createOrder(body, userId);
  }
}
