import { Module } from '@nestjs/common';
import { ShippingController } from 'src/routes/shipping/shipping.controller';
import { ShippingRepository } from 'src/routes/shipping/shipping.repo';
import { ShippingService } from 'src/routes/shipping/shipping.service';

@Module({
  controllers: [ShippingController],
  providers: [ShippingService, ShippingRepository],
})
export class ShippingModule {}
