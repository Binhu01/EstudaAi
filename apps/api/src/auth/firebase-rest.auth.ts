import { HttpException, ServiceUnavailableException, UnauthorizedException } from '@nestjs/common';
import { IdentityVerifier } from '../contracts';
import { AuthGateway, AuthSessionResponse } from './auth.gateway';

export class FirebaseRestAuth implements AuthGateway {
  constructor(private readonly apiKey: string | undefined, private readonly identity: IdentityVerifier, private readonly fetcher: typeof fetch = fetch) {}
  private async request(action: string, body: object | URLSearchParams, signal?: AbortSignal, reset = false): Promise<Record<string, unknown>> {
    if (!this.apiKey?.trim()) throw new ServiceUnavailableException();
    const refresh = action === 'token';
    const url = new URL(refresh ? 'https://securetoken.googleapis.com/v1/token' : 'https://identitytoolkit.googleapis.com/v1/accounts:' + action);
    url.searchParams.set('key', this.apiKey);
    try {
      const response = await this.fetcher(url, {
        method:'POST', redirect:'error', signal: signal ? AbortSignal.any([signal, AbortSignal.timeout(10_000)]) : AbortSignal.timeout(10_000),
        headers:{'Content-Type': refresh ? 'application/x-www-form-urlencoded' : 'application/json'},
        body: refresh ? String(body) : JSON.stringify(body),
      });
      const data: unknown = await response.json();
      if (!data || typeof data !== 'object' || Array.isArray(data)) throw new ServiceUnavailableException();
      const record = data as Record<string, unknown>;
      if (!response.ok) {
        const error = record.error as {message?:unknown} | undefined;
        const message = typeof error?.message === 'string' ? error.message : '';
        if (reset && /^EMAIL_NOT_FOUND\b/.test(message)) return {};
        if (response.status === 429 || /^TOO_MANY_ATTEMPTS/.test(message)) throw new HttpException('Aguarde um momento.', 429);
        if (/^(INVALID_LOGIN_CREDENTIALS|EMAIL_NOT_FOUND|INVALID_PASSWORD|INVALID_ID_TOKEN|TOKEN_EXPIRED|INVALID_REFRESH_TOKEN|USER_DISABLED|USER_NOT_FOUND|EMAIL_EXISTS|WEAK_PASSWORD|INVALID_EMAIL)\b/.test(message)) throw new UnauthorizedException();
        throw new ServiceUnavailableException();
      }
      return record;
    } catch (error) {
      if (error instanceof HttpException) throw error;
      throw new ServiceUnavailableException();
    }
  }
  private async session(data: Record<string, unknown>, refresh = false): Promise<AuthSessionResponse> {
    const idToken = data[refresh ? 'id_token' : 'idToken'];
    const refreshToken = data[refresh ? 'refresh_token' : 'refreshToken'];
    const rawExpiry = data[refresh ? 'expires_in' : 'expiresIn'];
    if (typeof idToken !== 'string' || !idToken || idToken.length > 8192 ||
        typeof refreshToken !== 'string' || !refreshToken || refreshToken.length > 8192 ||
        typeof rawExpiry !== 'string' || !/^\d+$/.test(rawExpiry)) throw new ServiceUnavailableException();
    const expiresInSeconds = Number(rawExpiry);
    if (!Number.isSafeInteger(expiresInSeconds) || expiresInSeconds < 1 || expiresInSeconds > 86_400) throw new ServiceUnavailableException();
    try {
      if (!(await this.identity.verify(idToken)).externalId) throw new UnauthorizedException();
    } catch (error) {
      if (error instanceof HttpException && error.getStatus() === 503) throw error;
      throw new UnauthorizedException();
    }
    return {idToken, refreshToken, expiresInSeconds};
  }
  async register(email: string, password: string, signal?: AbortSignal) { return this.session(await this.request('signUp', {email,password,returnSecureToken:true}, signal)); }
  async login(email: string, password: string, signal?: AbortSignal) { return this.session(await this.request('signInWithPassword', {email,password,returnSecureToken:true}, signal)); }
  async refresh(refreshToken: string, signal?: AbortSignal) {
    return this.session(await this.request('token', new URLSearchParams({grant_type:'refresh_token',refresh_token:refreshToken}), signal), true);
  }
  async resetPassword(email: string, signal?: AbortSignal) { await this.request('sendOobCode', {requestType:'PASSWORD_RESET',email}, signal, true); }
}
