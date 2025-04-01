import { Module } from '@nestjs/common';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from 'src/database/entities/user.entity';
import { AuthProvider } from 'src/database/entities/auth-provider.entity';

@Module({
  imports: [TypeOrmModule.forFeature([User, AuthProvider])],
  controllers: [AuthController],
  providers: [AuthService],
})
export class AuthModule {}
