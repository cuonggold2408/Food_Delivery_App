import { Injectable } from '@nestjs/common';
import { CreateOrderDTO } from 'src/routes/order/order.dto';
import { OrderRepository } from 'src/routes/order/order.repo';
@Injectable()
export class OrderService {
  constructor(private readonly orderRepository: OrderRepository) {}

  async createOrder(body: CreateOrderDTO, userId: number) {
    const result = await this.orderRepository.createOrder(body, userId);
    return result;
  }

  async getUserOrders(userId: number) {
    return this.orderRepository.getUserOrders(userId);
  }
}
