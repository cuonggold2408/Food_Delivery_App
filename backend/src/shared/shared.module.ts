import { Global, Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { JwtModule } from '@nestjs/jwt';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MenuItem } from 'src/database/entities/menu-item.entity';
import { Restaurant } from 'src/database/entities/restaurant.entity';
import { User } from 'src/database/entities/user.entity';
import { AccessTokenGuard } from 'src/shared/guards/access-token.guard';
import { ApiKeyGuard } from 'src/shared/guards/api-key.guard';
import { AuthenticationGuard } from 'src/shared/guards/authentication.guard';
import { SharedUserRepository } from 'src/shared/repositories/shared-user.repo';
import { EmailService } from 'src/shared/services/email.service';
import { HashingService } from 'src/shared/services/hashing.service';
import { SeedService } from 'src/shared/services/seed.service';
import { TokenService } from 'src/shared/services/token.service';

const sharedServices = [
  HashingService,
  TokenService,
  SharedUserRepository,
  EmailService,
  SeedService,
];

@Global()
@Module({
  providers: [
    ...sharedServices,
    ApiKeyGuard,
    AccessTokenGuard,
    {
      provide: APP_GUARD,
      useClass: AuthenticationGuard,
    },
  ],
  exports: sharedServices,
  imports: [JwtModule, TypeOrmModule.forFeature([User, Restaurant, MenuItem])],
})
export class SharedModule {}
