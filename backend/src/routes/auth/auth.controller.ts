import { Controller, Post, Body, HttpStatus, HttpCode } from '@nestjs/common';
import { AuthService } from './auth.service';
import {
  LoginBodyDTO,
  LoginBodySwaggerDTO,
  LogoutBodyDTO,
  RefreshTokenBodyDTO,
  RegisterBodyDTO,
  SendOTPBodyDTO,
} from 'src/routes/auth/auth.dto';
import { IsPublic } from 'src/shared/decorators/auth.decorator';
import { ApiBody, ApiOperation } from '@nestjs/swagger';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  @IsPublic()
  @ApiOperation({ summary: 'Đăng ký tài khoản' })
  register(@Body() body: RegisterBodyDTO) {
    return this.authService.register(body);
  }

  @Post('send-otp')
  @IsPublic()
  @ApiOperation({ summary: 'Gửi mã OTP' })
  sendOTP(@Body() body: SendOTPBodyDTO) {
    return this.authService.sendOTP(body);
  }

  @Post('login')
  @IsPublic()
  @ApiOperation({ summary: 'Đăng nhập' })
  @ApiBody({ type: LoginBodySwaggerDTO })
  login(@Body() body: LoginBodyDTO) {
    return this.authService.login(body);
  }

  @Post('refresh-token')
  @IsPublic()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Làm mới token' })
  refreshToken(@Body() body: RefreshTokenBodyDTO) {
    return this.authService.refreshToken(body);
  }

  @Post('logout')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Đăng xuất' })
  logout(@Body() body: LogoutBodyDTO) {
    return this.authService.logout(body);
  }
}
