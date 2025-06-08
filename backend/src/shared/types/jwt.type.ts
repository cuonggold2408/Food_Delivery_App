export interface AccessTokenPayloadCreate {
  user_id: number;
  user_role: string;
  provider_name: string;
}

export interface AccessTokenPayload extends AccessTokenPayloadCreate {
  iat: number;
  exp: number;
}

export interface RefreshTokenPayloadCreate {
  user_id: number;
  user_role: string;
}

export interface RefreshTokenPayload extends RefreshTokenPayloadCreate {
  iat: number;
  exp: number;
}
