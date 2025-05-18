import { Injectable } from '@nestjs/common';
import { ShippingRepository } from 'src/routes/shipping/shipping.repo';

@Injectable()
export class ShippingService {
  constructor(private readonly shippingRepository: ShippingRepository) {}

  async getShippingFee(body: {
    origin: { latitude: number; longitude: number };
    destination: { latitude: number; longitude: number };
  }) {
    return this.shippingRepository.getShippingFee(body);
  }
}
