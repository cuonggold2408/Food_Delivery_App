import { Global, Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { JwtModule } from '@nestjs/jwt';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MenuItem } from 'src/database/entities/menu-item.entity';
import { CustomizationCategory } from 'src/database/entities/restaurant/category/customization-category.entity';
import { CustomizationOption } from 'src/database/entities/restaurant/category/customization-option.entity';
import { ItemCustomizationCategory } from 'src/database/entities/restaurant/category/item-customization-category.entity';
import { MenuCategory } from 'src/database/entities/restaurant/category/menu-categories.entity';
import { Promotion } from 'src/database/entities/restaurant/promotions/promotion.entity';
import { RestaurantCategoryMapping } from 'src/database/entities/restaurant/restaurant-category-mapping.entity';
import { RestaurantCategory } from 'src/database/entities/restaurant/restaurant-category.entity';
import { Restaurant } from 'src/database/entities/restaurant/restaurant.entity';
import { User } from 'src/database/entities/user.entity';
import { AccessTokenGuard } from 'src/shared/guards/access-token.guard';
import { PaymentApiKeyGuard } from 'src/shared/guards/payment-api-key.guard';
import { AuthenticationGuard } from 'src/shared/guards/authentication.guard';
import { SharedUserRepository } from 'src/shared/repositories/shared-user.repo';
import { EmailService } from 'src/shared/services/email.service';
import { HashingService } from 'src/shared/services/hashing.service';
import { SeedService } from 'src/shared/services/seed.service';
import { TokenService } from 'src/shared/services/token.service';
import { SharedPaymentRepository } from 'src/shared/repositories/shared-payment.repo';
import { Payment } from 'src/database/entities/payment/payment.entity';

const sharedServices = [
  HashingService,
  TokenService,
  SharedUserRepository,
  EmailService,
  SeedService,
  SharedPaymentRepository,
];

@Global()
@Module({
  providers: [
    ...sharedServices,
    PaymentApiKeyGuard,
    AccessTokenGuard,
    {
      provide: APP_GUARD,
      useClass: AuthenticationGuard,
    },
  ],
  exports: sharedServices,
  imports: [
    JwtModule,
    TypeOrmModule.forFeature([
      User,
      Restaurant,
      MenuItem,
      RestaurantCategory,
      RestaurantCategoryMapping,
      Promotion,
      CustomizationOption,
      CustomizationCategory,
      ItemCustomizationCategory,
      MenuCategory,
      Payment,
    ]),
  ],
})
export class SharedModule {}
