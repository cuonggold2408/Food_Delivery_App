import otpGenerator from 'otp-generator';
import path from 'path';
import { CANCEL_PAYMENT_JOB_NAME } from 'src/shared/constants/queue.constant';
import { v4 as uuidv4 } from 'uuid';
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

export const generateRandomFileName = (fileName: string) => {
  const extension = path.extname(fileName);
  return `${uuidv4()}${extension}`;
};
