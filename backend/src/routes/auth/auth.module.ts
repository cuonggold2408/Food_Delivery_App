import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from 'src/database/entities/user.entity';
import { AuthProvider } from 'src/database/entities/auth-provider.entity';
import { AuthRepository } from 'src/routes/auth/auth.repo';
import { VerificationCode } from 'src/database/entities/verification-code.entity';
import { AuthController } from 'src/routes/auth/auth.controller';
import { AuthService } from 'src/routes/auth/auth.service';

@Module({
  imports: [TypeOrmModule.forFeature([User, AuthProvider, VerificationCode])],
  controllers: [AuthController],
  providers: [AuthService, AuthRepository],
})
export class AuthModule {}
