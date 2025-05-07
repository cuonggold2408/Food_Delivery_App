import { Module } from '@nestjs/common';
import { CartController } from './cart.controller';
import { CartService } from './cart.service';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Cart } from 'src/database/entities/cart/cart.entity';
import { CartItem } from 'src/database/entities/cart/cart-item.entity';
import { CartItemCustomization } from 'src/database/entities/cart/cart-item-customization.entity';
import { Restaurant } from 'src/database/entities/restaurant/restaurant.entity';
import { MenuItem } from 'src/database/entities/menu-item.entity';
import { CartRepository } from 'src/routes/cart/cart.repo';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Cart,
      CartItem,
      CartItemCustomization,
      Restaurant,
      MenuItem,
    ]),
  ],
  controllers: [CartController],
  providers: [CartService, CartRepository],
})
export class CartModule {}
