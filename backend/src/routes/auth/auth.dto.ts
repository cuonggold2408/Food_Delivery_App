import { createZodDto } from '@anatine/zod-nestjs';
import {
  LoginBodySchema,
  LoginBodySwaggerSchema,
  LoginResponseSchema,
  LogoutBodySchema,
  RefreshTokenBodySchema,
  RefreshTokenResponseSchema,
  RegisterBodySchema,
  RegisterResponseSchema,
  SendOTPBodySchema,
} from 'src/routes/auth/auth.model';

export class RegisterBodyDTO extends createZodDto(RegisterBodySchema) {}
export class RegisterResponseDTO extends createZodDto(RegisterResponseSchema) {}

export class SendOTPBodyDTO extends createZodDto(SendOTPBodySchema) {}

export class LoginBodyDTO extends createZodDto(LoginBodySchema) {}
export class LoginBodySwaggerDTO extends createZodDto(LoginBodySwaggerSchema) {}
export class LoginResponseDTO extends createZodDto(LoginResponseSchema) {}

export class RefreshTokenBodyDTO extends createZodDto(RefreshTokenBodySchema) {}
export class RefreshTokenResponseDTO extends createZodDto(
  RefreshTokenResponseSchema,
) {}

export class LogoutBodyDTO extends createZodDto(LogoutBodySchema) {}
