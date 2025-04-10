export interface AccessTokenPayloadCreate {
  user_id: number;
  provider_name: string;
}

export interface AccessTokenPayload extends AccessTokenPayloadCreate {
  iat: number;
  exp: number;
}

export interface RefreshTokenPayloadCreate {
  user_id: number;
}

export interface RefreshTokenPayload extends RefreshTokenPayloadCreate {
  iat: number;
  exp: number;
}
