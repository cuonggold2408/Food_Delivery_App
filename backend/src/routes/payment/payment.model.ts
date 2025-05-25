import { z } from 'zod';

export const PaymentTransactionSchema = z.object({
  id: z.number(),
  gateway: z.string(),
  transaction_date: z.date(),
  account_number: z.string().nullable(),
  sub_account: z.string().nullable(),
  amount_in: z.string(),
  amount_out: z.string(),
  accumulated: z.string(),
  code: z.string().nullable(),
  transaction_content: z.string().nullable(),
  reference_number: z.string().nullable(),
  body: z.string().nullable(),
  created_at: z.date(),
});

export type PaymentTransactionType = z.infer<typeof PaymentTransactionSchema>;

export const WebhookPaymentBodySchema = z.object({
  id: z.number(), // ID giao dịch trên Sepay
  gateway: z.string(), // Brand name của ngân hàng
  transaction_date: z.string(), // Thời gian xảy ra giao dịch phía ngân hàng
  account_number: z.string().nullable(), // Số tài khoản ngân hàng
  code: z.string().nullable(), // Mã code thanh toán (sepay tự nhận diện dựa vào cấu hình)
  content: z.string().nullable(), // Nội dung chuyển khoản
  transfer_type: z.enum(['in', 'out']), // Loại giao dịch
  transfer_amount: z.number(), // Số tiền chuyển khoản
  accumulated: z.number(), // Số dư tài khoản
  sub_account: z.string().nullable(), // Tên tài khoản ngân hàng phụ
  reference_code: z.string().nullable(), // Mã tham chiếu của tin nhắn sms
  description: z.string(), // Toàn bộ nội dung tin nhắn sms
});

export type WebhookPaymentBodyType = z.infer<typeof WebhookPaymentBodySchema>;
