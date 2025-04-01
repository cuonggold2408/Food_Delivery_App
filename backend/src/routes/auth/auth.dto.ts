import { Exclude } from 'class-transformer';
import { IsOptional, IsString } from 'class-validator';
import { Match } from 'src/shared/decorators/custom-validator.decorators';

export class LoginBodyDTO {
  constructor() {
    this.provider_name = 'original';
  }
  @IsString()
  email: string;

  @IsString()
  password: string;

  @IsOptional()
  @IsString()
  provider_name?: string; // 'original' hoặc 'google'

  @IsOptional()
  @IsString()
  provider_user_id?: string; // Chỉ dùng cho Google

  @IsOptional()
  @IsString()
  access_token?: string; // Chỉ dùng cho Google
}

export class RegisterBodyDTO extends LoginBodyDTO {
  @IsString()
  name: string;

  @IsString()
  @Match('password', { message: 'Mật khẩu không khớp' })
  confirmPassword: string;
}

export class RegisterResponseDTO {
  id: number;
  email: string;
  name: string;
  @Exclude() password: string;

  constructor(partial: Partial<RegisterResponseDTO>) {
    Object.assign(this, partial);
  }
}

export class LoginResponseDTO {
  accessToken: string;
  refreshToken: string;

  constructor(partial: Partial<LoginResponseDTO>) {
    Object.assign(this, partial);
  }
}

export class RefreshTokenBodyDTO {
  @IsString()
  refreshToken: string;
}

export class RefreshTokenResponseDTO extends LoginResponseDTO {}
