import { CanActivate, ExecutionContext, HttpException, UnauthorizedException } from '@nestjs/common';
import { Request } from 'express';
import { Reflector } from '@nestjs/core';
import { PUBLIC_ROUTE } from './public-route';
import { AppDependencies, User } from '../contracts';

export type AuthenticatedRequest = Request & { user: User };
export class AuthGuard implements CanActivate {
  private readonly reflector = new Reflector();
  constructor(private readonly dependencies: AppDependencies) {}
  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    // Public access is attached to the exact registered handlers, never to a URL prefix.
    if (this.reflector.getAllAndOverride<boolean>(PUBLIC_ROUTE, [context.getHandler(), context.getClass()])) return true;
    const authorization = request.headers.authorization;
    if (!authorization || authorization.length > 8192 || !/^Bearer [A-Za-z0-9._~-]+$/.test(authorization)) throw new UnauthorizedException();
    let externalId: string;
    try {
      externalId = (await this.dependencies.identity.verify(authorization.slice(7))).externalId;
      if (!externalId) throw new Error('Invalid identity');
    } catch (error) {
      if (error instanceof HttpException && error.getStatus() === 503) throw error;
      throw new UnauthorizedException();
    }
    request.user = await this.dependencies.users.resolve(externalId);
    return true;
  }
}
