import { ExecutionContext, Injectable, SetMetadata } from '@nestjs/common';
import { ThrottlerGuard, ThrottlerRequest } from '@nestjs/throttler';
import { PUBLIC_ROUTE } from './public-route';
import { AuthenticatedRequest } from './auth.guard';
const RATE_GROUP = Symbol('rate-group');
export const RateGroup = (group: 'auth' | 'refresh') => SetMetadata(RATE_GROUP, group);
@Injectable()
export class IpThrottlerGuard extends ThrottlerGuard {
  private group(context: ExecutionContext): string {
    return this.reflector.getAllAndOverride<string>(RATE_GROUP, [context.getHandler(),context.getClass()]) ?? 'api';
  }
  protected async handleRequest(props: ThrottlerRequest) {
    const group = this.group(props.context);
    return super.handleRequest(group === 'api' ? props : {...props, limit:group === 'auth' ? 10 : 60, ttl:60_000, blockDuration:60_000});
  }
  protected generateKey(context: ExecutionContext, tracker: string, name: string) { return `${name}:ip:${this.group(context)}:${tracker}`; }
}
@Injectable()
export class UserThrottlerGuard extends ThrottlerGuard {
  async canActivate(context: ExecutionContext) {
    if (this.reflector.getAllAndOverride<boolean>(PUBLIC_ROUTE,[context.getHandler(),context.getClass()])) return true;
    return super.canActivate(context);
  }
  protected async getTracker(request: AuthenticatedRequest) { return request.user.id; }
  protected generateKey(_context: ExecutionContext, tracker: string, name: string) { return `${name}:user:${tracker}`; }
}
