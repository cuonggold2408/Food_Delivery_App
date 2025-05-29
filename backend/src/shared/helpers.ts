import otpGenerator from 'otp-generator';
import { CANCEL_PAYMENT_JOB_NAME } from 'src/shared/constants/queue.constant';
export const generateOTP = () => {
  const otp = otpGenerator.generate(4, {
    upperCaseAlphabets: false,
    specialChars: false,
    lowerCaseAlphabets: false,
    digits: true,
  });
  return otp;
};

export const generateCancelPaymentJobId = (paymentId: number) => {
  return `${CANCEL_PAYMENT_JOB_NAME}-${paymentId}`;
};

export const generateRoomUserId = (userId: number) => {
  return `userId-${userId}`;
};
