export interface AuthSessionResponse { idToken: string; refreshToken: string; expiresInSeconds: number }
export interface AuthGateway {
  register(email: string, password: string, signal?: AbortSignal): Promise<AuthSessionResponse>;
  login(email: string, password: string, signal?: AbortSignal): Promise<AuthSessionResponse>;
  refresh(refreshToken: string, signal?: AbortSignal): Promise<AuthSessionResponse>;
  resetPassword(email: string, signal?: AbortSignal): Promise<void>;
}
