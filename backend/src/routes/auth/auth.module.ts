import { Module } from '@nestjs/common';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from 'src/database/entities/user.entity';
import { AuthProvider } from 'src/database/entities/auth-provider.entity';
import { AuthRepository } from 'src/routes/auth/auth.repo';
import { VerificationCode } from 'src/database/entities/verification-code.entity';

@Module({
  imports: [TypeOrmModule.forFeature([User, AuthProvider, VerificationCode])],
  controllers: [AuthController],
  providers: [AuthService, AuthRepository],
})
export class AuthModule {}
