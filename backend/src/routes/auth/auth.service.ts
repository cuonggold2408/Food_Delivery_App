import {
  Injectable,
  BadRequestException,
  UnprocessableEntityException,
  UnauthorizedException,
  // UnauthorizedException,
  // UnprocessableEntityException,
} from '@nestjs/common';
import { TokenService } from 'src/shared/services/token.service';
import { HashingService } from 'src/shared/services/hashing.service';
import {
  LoginBodyType,
  RefreshTokenBodyType,
  RegisterBodyType,
  SendOTPBodyType,
} from 'src/routes/auth/auth.model';
import { AuthRepository } from 'src/routes/auth/auth.repo';
import { SharedUserRepository } from 'src/shared/repositories/shared-user.repo';
import { generateOTP } from 'src/shared/helpers';
import { addMilliseconds } from 'date-fns';
import envConfig from 'src/shared/config';
import ms, { StringValue } from 'ms';
import { TypeVerificationCode } from 'src/database/entities/verification-code.entity';
import { EmailService } from 'src/shared/services/email.service';
import { AccessTokenPayloadCreate } from 'src/shared/types/jwt.type';

@Injectable()
export class AuthService {
  constructor(
    private readonly tokenService: TokenService,
    private readonly hashingService: HashingService,
    private readonly authRepository: AuthRepository,
    private readonly sharedUserRepository: SharedUserRepository,
    private readonly emailService: EmailService,
  ) {}

  async register(body: RegisterBodyType) {
    const { email, password, name, code } = body;

    const verificationCode =
      await this.authRepository.findUniqueVerificationCode({
        email,
        code,
        type: TypeVerificationCode.REGISTER,
      });

    if (!verificationCode) {
      throw new UnprocessableEntityException([
        {
          field: 'code',
          message: 'Mã OTP không hợp lệ',
        },
      ]);
    }

    if (verificationCode.expires_at < new Date()) {
      throw new UnprocessableEntityException([
        {
          field: 'code',
          message: 'Mã OTP đã hết hạn',
        },
      ]);
    }

    const hashedPassword = await this.hashingService.hash(password);
    try {
      return await this.authRepository.createUser({
        email,
        password: hashedPassword,
        name,
      });
    } catch (error) {
      if (error.code === '23505') {
        throw new UnprocessableEntityException([
          {
            field: 'email',
            message: 'Email đã tồn tại',
          },
        ]);
      }

      throw new BadRequestException(error.message);
    }
  }

  async sendOTP(body: SendOTPBodyType) {
    // Kiểm tra xem email đã tồn tại trong cơ sở dữ liệu hay chưa
    const user = await this.sharedUserRepository.findUnique({
      email: body.email,
    });
    if (user) {
      throw new UnprocessableEntityException([
        {
          field: 'email',
          message: 'Email đã tồn tại',
        },
      ]);
    }

    // Tạo mã OTP
    const code = generateOTP();

    await this.authRepository.createVerificationCode({
      email: body.email,
      code,
      expires_at: addMilliseconds(
        new Date(),
        ms(envConfig.OTP_EXPIRES_IN as StringValue),
      ),
      type: body.type,
    });

    const { error } = await this.emailService.sendOTP({
      email: body.email,
      code,
    });

    if (error) {
      throw new UnprocessableEntityException([
        {
          field: 'code',
          message: 'Gửi mã OTP thất bại',
        },
      ]);
    }

    return {
      message: 'Gửi mã OTP thành công',
    };
  }

  async login(body: LoginBodyType) {
    const user = await this.sharedUserRepository.findUnique({
      email: body.email,
    });

    if (!user) {
      throw new UnprocessableEntityException([
        {
          field: 'email',
          message: 'Email không tồn tại',
        },
      ]);
    }

    const checkPassword = await this.hashingService.compare(
      body.password,
      user.password,
    );

    if (!checkPassword) {
      throw new UnprocessableEntityException([
        {
          field: 'password',
          message: 'Tài khoản hoặc mật khẩu không chính xác',
        },
      ]);
    }
    const tokens = await this.generateTokens({
      user_id: user.user_id,
      provider_name: body.provider_name,
    });

    return tokens;
  }

  async generateTokens({ user_id, provider_name }: AccessTokenPayloadCreate) {
    const [accessToken, refreshToken] = await Promise.all([
      this.tokenService.signAccessToken({ user_id, provider_name }),
      this.tokenService.signRefreshToken({ user_id }),
    ]);

    const decodedRefreshToken =
      await this.tokenService.verifyRefreshToken(refreshToken);
    const actualProviderName = provider_name || 'local';
    await this.authRepository.createRefreshToken({
      user_id: user_id,
      provider_name: actualProviderName,
      refresh_token: refreshToken,
      expired_at: new Date(decodedRefreshToken.exp * 1000),
    });

    return { accessToken, refreshToken };
  }

  async refreshToken({ refresh_token }: RefreshTokenBodyType) {
    // 1. Kiểm tra refresh token có hợp lệ hay không
    const { user_id } =
      await this.tokenService.verifyRefreshToken(refresh_token);

    // 2. Kiểm tra refresh token có tồn tại trong cơ sở dữ liệu hay không
    const refreshTokenInDB = await this.authRepository.findUniqueRefreshToken({
      refresh_token,
      user_id,
    });

    if (!refreshTokenInDB) {
      throw new UnauthorizedException('Refresh token không tồn tại');
    }
    try {
      // 3. Xóa refresh token cũ
      await this.authRepository.deleteRefreshToken({
        refresh_token,
      });

      // 4. Tạo mới access token và refresh token
      return await this.generateTokens({
        user_id,
        provider_name: refreshTokenInDB.provider_name,
      });
    } catch {
      throw new UnauthorizedException('Refresh token không hợp lệ');
    }
  }

  async logout({ refresh_token }: { refresh_token: string }) {
    try {
      // 1. Kiểm tra refresh token có hợp lệ hay không
      await this.tokenService.verifyRefreshToken(refresh_token);

      // 2. Xóa refresh token trong cơ sở dữ liệu
      await this.authRepository.deleteRefreshToken({
        refresh_token,
      });

      return {
        message: 'Đăng xuất thành công',
      };
    } catch {
      throw new BadRequestException('Có lỗi xảy ra khi đăng xuất');
    }
  }
}
