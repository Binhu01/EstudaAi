import { Auth } from 'firebase-admin/auth';
import { ServiceUnavailableException, UnauthorizedException } from '@nestjs/common';
import { IdentityVerifier } from '../contracts';

export class FirebaseIdentityVerifier implements IdentityVerifier {
  constructor(private readonly auth: Pick<Auth, 'verifyIdToken'>) {}
  async verify(token: string) {
    try {
      // Admin validates signature, project, expiry and revocation. Never decode-only.
      const claims = await this.auth.verifyIdToken(token, true);
      return { externalId: claims.uid };
    } catch (error) {
      const code = (error as { code?: string }).code;
      if (code && ['auth/id-token-expired', 'auth/id-token-revoked', 'auth/invalid-id-token', 'auth/argument-error', 'auth/invalid-argument', 'auth/user-disabled', 'auth/user-not-found'].includes(code)) {
        throw new UnauthorizedException();
      }
      throw new ServiceUnavailableException();
    }
  }
}
