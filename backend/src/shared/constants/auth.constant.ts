export const REQUEST_USER_KEY = 'user';

export const AuthType = {
  Bearer: 'Bearer',
  None: 'None',
  PaymentAPIKey: 'PaymentAPIKey',
} as const;

export type AuthTypeType = (typeof AuthType)[keyof typeof AuthType];

export const ConditionGuard = {
  And: 'and',
  Or: 'or',
} as const;
export type ConditionGuardType =
  (typeof ConditionGuard)[keyof typeof ConditionGuard];

export const TypeOfVerificationCode = {
  REGISTER: 'REGISTER',
  FORGOT_PASSWORD: 'FORGOT_PASSWORD',
} as const;
export type TypeVerificationCode =
  (typeof TypeOfVerificationCode)[keyof typeof TypeOfVerificationCode];
