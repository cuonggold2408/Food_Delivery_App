import { config } from 'dotenv';
import fs from 'fs';
import path from 'path';
import z from 'zod';

config({
  path: '.env',
});

// Kiểm tra coi thử có file .env hay chưa
if (!fs.existsSync(path.resolve('.env'))) {
  console.log('Không tìm thấy file .env');
  process.exit(1);
}

const configSchema = z.object({
  ACCESS_TOKEN_SECRET: z.string(),
  ACCESS_TOKEN_EXPIRES_IN: z.string(),
  REFRESH_TOKEN_SECRET: z.string(),
  REFRESH_TOKEN_EXPIRES_IN: z.string(),
  PAYMENT_API_KEY: z.string(),
  OTP_EXPIRES_IN: z.string(),
  RESEND_API_KEY: z.string(),
  REDIS_URL: z.string(),
  ACC_BANK: z.string(),
  SHORT_BANK: z.string(),
  FIREBASE_SERVICE_ACCOUNT_KEY: z.string(),
});

const configServer = configSchema.safeParse(process.env);

if (!configServer.success) {
  console.log('Các giá trị khai báo trong file .env không hợp lệ');
  console.error(configServer.error);
  process.exit(1);
}

const envConfig = configServer.data;

export default envConfig;
