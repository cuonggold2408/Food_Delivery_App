import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { SharedModule } from './shared/shared.module';
import { DatabaseModule } from './database/database.module';
import { ConfigModule } from '@nestjs/config';
import { APP_FILTER, APP_INTERCEPTOR, APP_PIPE } from '@nestjs/core';
import CustomZodValidationPipe from 'src/shared/pipes/custom-zod-validation.pipe';
import { ZodSerializerInterceptor } from 'nestjs-zod';
import { HttpExceptionFilter } from 'src/shared/filters/http-exception.filter';
import { AuthModule } from 'src/routes/auth/auth.module';
import { UserModule } from 'src/routes/user/user.module';
import { SearchModule } from 'src/routes/search/search.module';
import { RestaurantModule } from 'src/routes/restaurant/restaurant.module';
import { CartModule } from 'src/routes/cart/cart.module';
import { ShippingModule } from 'src/routes/shipping/shipping.module';
import { PaymentModule } from 'src/routes/payment/payment.module';
import { OrderModule } from './routes/order/order.module';
import { BullModule } from '@nestjs/bullmq';
import { PaymentConsumer } from 'src/queues/payment.consumer';
import envConfig from 'src/shared/config';
import { WebsocketModule } from 'src/websockets/websocket.module';
import { FirebaseModule } from './routes/firebase/firebase.module';
import { MediaModule } from './routes/media/media.module';
import { ReviewModule } from './routes/review/review.module';
import { AdminModule } from './routes/admin/admin.module';

@Module({
  imports: [
    SharedModule,
    DatabaseModule,
    AuthModule,
    UserModule,
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    BullModule.forRoot({
      connection: {
        url: envConfig.REDIS_URL,
      },
    }),
    RestaurantModule,
    SearchModule,
    CartModule,
    ShippingModule,
    PaymentModule,
    OrderModule,
    WebsocketModule,
    FirebaseModule,
    MediaModule,
    ReviewModule,
    AdminModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    {
      provide: APP_PIPE,
      useClass: CustomZodValidationPipe,
    },
    {
      provide: APP_INTERCEPTOR,
      useClass: ZodSerializerInterceptor,
    },
    {
      provide: APP_FILTER,
      useClass: HttpExceptionFilter,
    },
    PaymentConsumer,
  ],
})
export class AppModule {}
