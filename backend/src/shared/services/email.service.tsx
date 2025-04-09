import { Injectable } from '@nestjs/common';
import { Resend } from 'resend';
import envConfig from 'src/shared/config';
import { OTPEmail } from 'emails/otp';
import * as React from 'react';

@Injectable()
export class EmailService {
  private resend: Resend;
  constructor() {
    this.resend = new Resend(envConfig.RESEND_API_KEY);
  }

  sendOTP(payload: { email: string; code: string }) {
    const subject = 'Mã OTP: ';
    return this.resend.emails.send({
      from: 'Food_Delivery <no-reply@notenqc.online>',
      to: [payload.email],
      subject: subject,
      react: <OTPEmail otpCode={payload.code} title={subject} />,
    });
  }
}
