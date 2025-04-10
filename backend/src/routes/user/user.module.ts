import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UserAddress } from 'src/database/entities/user-address.entity';
import { User } from 'src/database/entities/user.entity';
import { UserController } from 'src/routes/user/user.controller';
import { UserAddressRepository } from 'src/routes/user/user.repo';
import { UserService } from 'src/routes/user/user.service';

@Module({
  imports: [TypeOrmModule.forFeature([User, UserAddress])],
  controllers: [UserController],
  providers: [UserService, UserAddressRepository],
})
export class UserModule {}
