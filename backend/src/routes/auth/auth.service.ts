import {
  Injectable,
  BadRequestException,
  UnauthorizedException,
  UnprocessableEntityException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from 'src/database/entities/user.entity';
import { AuthProvider } from 'src/database/entities/auth-provider.entity';
import { LoginBodyDTO, RegisterBodyDTO } from 'src/routes/auth/auth.dto';
import { TokenService } from 'src/shared/services/token.service';
import { HashingService } from 'src/shared/services/hashing.service';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(AuthProvider)
    private readonly authProviderRepository: Repository<AuthProvider>,
    private readonly tokenService: TokenService,
    private readonly hashingService: HashingService,
  ) {}

  async register(body: RegisterBodyDTO) {
    const { email, password, name } = body;

    if (!email || !password || !name) {
      throw new BadRequestException('Không được để trống thông tin');
    }
    const existingUser = await this.userRepository.findOne({
      where: { email: body.email },
    });
    if (existingUser) throw new BadRequestException('Email đã tồn tại');

    const hashedPassword = await this.hashingService.hash(body.password);
    const newUser = this.userRepository.create({
      email: body.email,
      name: body.name,
      password: hashedPassword,
      user_role: 'customer',
    });
    return await this.userRepository.save(newUser);
  }

  async login(body: LoginBodyDTO) {
    const user = await this.userRepository.findOne({
      where: {
        email: body.email,
      },
    });

    if (!user) {
      throw new UnauthorizedException('Tài khoản không tồn tại');
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
    const tokens = await this.generateTokens(
      { userId: user.user_id },
      body.provider_name,
    );
    return tokens;
  }

  async generateTokens(payload: { userId: number }, provider_name?: string) {
    const [accessToken, refreshToken] = await Promise.all([
      this.tokenService.signAccessToken(payload),
      this.tokenService.signRefreshToken(payload),
    ]);

    const decodedRefreshToken =
      await this.tokenService.verifyRefreshToken(refreshToken);
    const actualProviderName = provider_name || 'original';
    await this.authProviderRepository.upsert(
      {
        user_id: payload.userId,
        provider_name: actualProviderName,
        refresh_token: refreshToken,
        expired_at: new Date(decodedRefreshToken.exp * 1000),
      },
      ['user_id', 'provider_name'], // Dựa trên user_id và provider_name để upsert
    );

    return { accessToken, refreshToken };
  }
}
