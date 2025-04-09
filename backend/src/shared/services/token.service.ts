import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import envConfig from 'src/shared/config';
import {
  AccessTokenPayload,
  AccessTokenPayloadCreate,
  RefreshTokenPayload,
  RefreshTokenPayloadCreate,
} from 'src/shared/types/jwt.type';
import { v4 as uuidv4 } from 'uuid';
import * as jwt from 'jsonwebtoken';

@Injectable()
export class TokenService {
  constructor(private readonly jwtService: JwtService) {}
  signAccessToken(payload: AccessTokenPayloadCreate) {
    return this.jwtService.sign(
      { ...payload, uuid: uuidv4() },
      {
        secret: envConfig.ACCESS_TOKEN_SECRET,
        expiresIn: envConfig.ACCESS_TOKEN_EXPIRES_IN,
        algorithm: 'HS256',
      },
    );
  }

  signRefreshToken(payload: RefreshTokenPayloadCreate) {
    return this.jwtService.sign(
      { ...payload, uuid: uuidv4() },
      {
        secret: envConfig.REFRESH_TOKEN_SECRET,
        expiresIn: envConfig.REFRESH_TOKEN_EXPIRES_IN,
        algorithm: 'HS256',
      },
    );
  }

  async verifyAccessToken(token: string): Promise<AccessTokenPayload> {
    try {
      return await this.jwtService.verifyAsync(token, {
        secret: envConfig.ACCESS_TOKEN_SECRET,
      });
    } catch (error) {
      if (error instanceof jwt.JsonWebTokenError) {
        throw new UnauthorizedException({
          message: 'Access token không hợp lệ',
          error: 'INVALID_TOKEN',
        });
      } else if (error instanceof jwt.TokenExpiredError) {
        throw new UnauthorizedException({
          message: 'Access token đã hết hạn',
          error: 'TOKEN_EXPIRED',
        });
      }
      throw error;
    }
  }

  async verifyRefreshToken(token: string): Promise<RefreshTokenPayload> {
    try {
      return await this.jwtService.verifyAsync(token, {
        secret: envConfig.REFRESH_TOKEN_SECRET,
      });
    } catch (error) {
      if (error instanceof jwt.JsonWebTokenError) {
        throw new UnauthorizedException({
          message: 'Refresh token không hợp lệ',
          error: 'INVALID_REFRESH_TOKEN',
        });
      } else if (error instanceof jwt.TokenExpiredError) {
        throw new UnauthorizedException({
          message: 'Refresh token đã hết hạn',
          error: 'REFRESH_TOKEN_EXPIRED',
        });
      }
      throw error;
    }
  }
}
