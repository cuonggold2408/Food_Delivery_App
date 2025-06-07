import { Module } from '@nestjs/common';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { AdminRepository } from 'src/routes/admin/admin.repo';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Restaurant } from 'src/database/entities/restaurant/restaurant.entity';
import { MenuItem } from 'src/database/entities/menu-item.entity';
import { MenuCategory } from 'src/database/entities/restaurant/category/menu-categories.entity';
import { ItemCustomizationCategory } from 'src/database/entities/restaurant/category/item-customization-category.entity';
import { CustomizationCategory } from 'src/database/entities/restaurant/category/customization-category.entity';
import { Order } from 'src/database/entities/order/order.entity';
import { FirebaseModule } from 'src/routes/firebase/firebase.module';
import { User } from 'src/database/entities/user.entity';
import { Promotion } from 'src/database/entities/restaurant/promotions/promotion.entity';
import { Review } from 'src/database/entities/review/review.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Restaurant,
      MenuItem,
      MenuCategory,
      ItemCustomizationCategory,
      CustomizationCategory,
      Order,
      User,
      Promotion,
      Review,
    ]),
    FirebaseModule,
  ],
  controllers: [AdminController],
  providers: [AdminService, AdminRepository],
})
export class AdminModule {}
