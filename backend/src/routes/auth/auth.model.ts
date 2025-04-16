import { TypeOfVerificationCode } from 'src/shared/constants/auth.constant';
import { UserSchema } from 'src/shared/models/shared-user.model';
import { z } from 'zod';

import { extendZodWithOpenApi } from '@anatine/zod-openapi';
import { OpenAPIRegistry } from '@asteasolutions/zod-to-openapi';

extendZodWithOpenApi(z);

const registry = new OpenAPIRegistry();

export const VerificationCodeSchema = z.object({
  email: z.string().email(),
  type: z.enum([
    TypeOfVerificationCode.REGISTER,
    TypeOfVerificationCode.FORGOT_PASSWORD,
  ]),
  code: z.string().length(4),
  expires_at: z.date(),
});

export const RegisterBodySchema = UserSchema.pick({
  email: true,
  password: true,
  name: true,
})
  .extend({
    confirmPassword: z.string().min(8).max(100),
    code: z.string().length(4),
  })
  .strict()
  .superRefine(({ confirmPassword, password }, ctx) => {
    if (confirmPassword !== password) {
      ctx.addIssue({
        code: 'custom',
        message: 'Password and confirm password must match',
        path: ['confirmPassword'],
      });
    }
  });

export const SendOTPBodySchema = VerificationCodeSchema.pick({
  email: true,
  type: true,
}).strict();

export const LoginBodySchema = UserSchema.pick({
  email: true,
  password: true,
})
  .extend({
    provider_name: z.string().default('local'),
  })
  .strict();

export const LoginBodySwaggerSchema = registry.register(
  'LoginBody',
  LoginBodySchema.omit({ provider_name: true }).openapi({
    example: {
      email: 'example@gmail.com',
      password: 'yourpassword',
    },
  }),
);

export const RefreshTokenBodySchema = z
  .object({
    refresh_token: z.string(),
  })
  .strict();

export const LogoutBodySchema = RefreshTokenBodySchema;

export const RegisterResponseSchema = UserSchema.omit({
  password: true,
});

export const LoginResponseSchema = z.object({
  access_token: z.string(),
  refresh_token: z.string(),
  user: UserSchema.omit({ password: true }),
});

export const RefreshTokenResponseSchema = LoginResponseSchema.omit({
  user: true,
});

export type RegisterBodyType = z.infer<typeof RegisterBodySchema>;
export type RegisterResponseType = z.infer<typeof RegisterResponseSchema>;
export type VerificationCodeType = z.infer<typeof VerificationCodeSchema>;
export type SendOTPBodyType = z.infer<typeof SendOTPBodySchema>;
export type LoginBodyType = z.infer<typeof LoginBodySchema>;
export type LoginResponseType = z.infer<typeof LoginResponseSchema>;
export type RefreshTokenBodyType = z.infer<typeof RefreshTokenBodySchema>;
export type RefreshTokenResponseType = z.infer<
  typeof RefreshTokenResponseSchema
>;
export type LogoutBodyType = RefreshTokenBodyType;
