import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MenuItem } from 'src/database/entities/menu-item.entity';
import { RestaurantCategory } from 'src/database/entities/restaurant/restaurant-category.entity';
import { Restaurant } from 'src/database/entities/restaurant/restaurant.entity';
import { ProductController } from 'src/routes/product/product.controller';
import { ProductRepository } from 'src/routes/product/product.repo';
import { ProductService } from 'src/routes/product/product.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([MenuItem, Restaurant, RestaurantCategory]),
  ],
  controllers: [ProductController],
  providers: [ProductService, ProductRepository],
})
export class ProductModule {}
