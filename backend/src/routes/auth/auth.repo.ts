import { BadRequestException, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { AuthProvider } from 'src/database/entities/auth-provider.entity';
import { User } from 'src/database/entities/user.entity';
import {
  TypeVerificationCode,
  VerificationCode,
} from 'src/database/entities/verification-code.entity';
import {
  RegisterBodyType,
  VerificationCodeType,
} from 'src/routes/auth/auth.model';
import {
  AuthProviderType,
  UserRole,
  UserType,
} from 'src/shared/models/shared-user.model';
import { Repository } from 'typeorm';

@Injectable()
export class AuthRepository {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,

    @InjectRepository(VerificationCode)
    private readonly verificationCodeRepository: Repository<VerificationCode>,

    @InjectRepository(AuthProvider)
    private readonly authProviderRepository: Repository<AuthProvider>,
  ) {}
  async createUser(
    user: Omit<RegisterBodyType, 'confirmPassword' | 'code'>,
  ): Promise<Omit<UserType, 'password'>> {
    const newUser = this.userRepository.create({
      ...user,
    });

    const savedUser = await this.userRepository.save(newUser);
    return {
      user_id: savedUser.user_id,
      email: savedUser.email,
      name: savedUser.name,
      user_role: UserRole.CUSTOMER,
      created_at: savedUser.created_at,
      updated_at: savedUser.updated_at,
    };
  }

  async createVerificationCode(
    payload: VerificationCodeType,
  ): Promise<VerificationCodeType> {
    await this.verificationCodeRepository.upsert(
      {
        email: payload.email,
        code: payload.code,
        expires_at: payload.expires_at,
        type: TypeVerificationCode[payload.type],
      },
      {
        conflictPaths: ['email'], // Xác định trường để kiểm tra conflict (upsert dựa trên email)
        skipUpdateIfNoValuesChanged: true, // Tùy chọn: không cập nhật nếu không thay đổi
      },
    );

    // Lấy bản ghi vừa upsert
    const savedOTP = await this.verificationCodeRepository.findOne({
      where: { email: payload.email },
    });

    if (!savedOTP) {
      throw new BadRequestException('Có lỗi xảy ra khi tạo mã xác thực');
    }

    return {
      email: savedOTP.email,
      code: savedOTP.code,
      expires_at: savedOTP.expires_at,
      type: savedOTP.type,
    };
  }

  async findUniqueVerificationCode(
    uniqueValue:
      | { email: string }
      | { email: string; type: TypeVerificationCode; code: string },
  ): Promise<VerificationCodeType | null> {
    const verificationCode = await this.verificationCodeRepository.findOne({
      where: uniqueValue,
    });

    if (!verificationCode) {
      return null;
    }

    return {
      email: verificationCode.email,
      code: verificationCode.code,
      expires_at: verificationCode.expires_at,
      type: verificationCode.type,
    };
  }

  createRefreshToken(data: {
    refresh_token: string;
    user_id: number;
    provider_name: string;
    expired_at: Date;
  }) {
    return this.authProviderRepository.upsert(
      {
        ...data,
      },
      {
        conflictPaths: ['user_id', 'provider_name'], // Xác định trường để kiểm tra conflict (upsert dựa trên user_id và provider_name)
        skipUpdateIfNoValuesChanged: true, // Tùy chọn: không cập nhật nếu không thay đổi
      },
    );
  }

  async findUniqueRefreshToken(
    uniqueObject: { refresh_token: string } & { user_id: number },
  ): Promise<Omit<
    AuthProviderType,
    'auth_id' | 'created_at' | 'updated_at' | 'provider_user_id'
  > | null> {
    const refreshToken = await this.authProviderRepository.findOne({
      where: uniqueObject,
    });

    if (!refreshToken) {
      return null;
    }

    return {
      user_id: refreshToken.user_id,
      provider_name: refreshToken.provider_name,
      refresh_token: refreshToken.refresh_token,
      expired_at: refreshToken.expired_at,
    };
  }

  async deleteRefreshToken(uniqueValue: { refresh_token: string }) {
    return await this.authProviderRepository.delete(uniqueValue);
  }
}
