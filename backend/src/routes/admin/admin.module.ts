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

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Restaurant,
      MenuItem,
      MenuCategory,
      ItemCustomizationCategory,
      CustomizationCategory,
    ]),
  ],
  controllers: [AdminController],
  providers: [AdminService, AdminRepository],
})
export class AdminModule {}
