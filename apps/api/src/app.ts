import 'reflect-metadata';
import { Controller, ExecutionContext, Get, Inject, Injectable, INestApplication, Module, Req, ServiceUnavailableException, ValidationPipe } from '@nestjs/common';
import { APP_GUARD, NestFactory } from '@nestjs/core';
import { SkipThrottle, ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { SwaggerModule, DocumentBuilder, ApiBearerAuth, ApiOkResponse, ApiProperty, ApiUnauthorizedResponse, ApiResponse } from '@nestjs/swagger';
import helmet from 'helmet';
import { randomUUID } from 'node:crypto';
import { Request, Response, NextFunction } from 'express';
import { AppDependencies } from './contracts';
import { AuthGuard, AuthenticatedRequest } from './auth/auth.guard';
import { SafeExceptionFilter } from './errors';
import { freeEntitlements } from './entitlements/entitlements';
import { PublicRoute } from './auth/public-route';

export const DEPENDENCIES = 'APP_DEPENDENCIES';

@Injectable()
class UserThrottlerGuard extends ThrottlerGuard {
  protected async getTracker(request: AuthenticatedRequest) {
    return `user:${request.user.id}`;
  }
  protected generateKey(_context: ExecutionContext, tracker: string, name: string) {
    return `${name}:${tracker}`;
  }
}

class ProfileResponse {
  @ApiProperty({ format: 'uuid' }) id!: string;
  @ApiProperty({ enum: ['FREE'] }) plan!: string;
}
class CapabilitiesResponse {
  @ApiProperty({ example: false }) advancedAi!: boolean;
  @ApiProperty({ example: false }) generatedQuestions!: boolean;
  @ApiProperty({ example: false }) advancedAnalytics!: boolean;
}
class EntitlementsResponse {
  @ApiProperty({ enum: ['FREE'] }) plan!: string;
  @ApiProperty({ type: CapabilitiesResponse }) capabilities!: CapabilitiesResponse;
}
class SafeErrorResponse {
  @ApiProperty({ enum: ['INVALID_INPUT', 'UNAUTHENTICATED', 'FORBIDDEN', 'NOT_FOUND', 'RATE_LIMITED', 'UNAVAILABLE', 'INTERNAL_ERROR'] }) code!: string;
  @ApiProperty({ description: 'Mensagem segura em português, sem detalhes internos.' }) message!: string;
  @ApiProperty({ format: 'uuid' }) requestId!: string;
}
class LiveResponse {
  @ApiProperty({ enum: ['ok'] }) status!: string;
}
class ReadyResponse {
  @ApiProperty({ enum: ['ready'] }) status!: string;
}

@SkipThrottle()
@PublicRoute()
@Controller('health')
class HealthController {
  constructor(@Inject(DEPENDENCIES) private readonly dependencies: AppDependencies) {}
  @Get('live')
  @ApiOkResponse({ type: LiveResponse })
  live() { return { status: 'ok' }; }
  @Get('ready')
  @ApiOkResponse({ type: ReadyResponse })
  @ApiResponse({ status: 503, type: SafeErrorResponse, description: 'Banco indisponível.' })
  async ready() {
    try {
      if (await this.dependencies.ready()) return { status: 'ready' };
    } catch { /* Report dependency unavailability without exposing its details. */ }
    throw new ServiceUnavailableException();
  }
}

@Controller('v1/me')
@ApiBearerAuth()
@ApiUnauthorizedResponse({ type: SafeErrorResponse, description: 'Sessão ausente ou inválida.' })
@ApiResponse({ status: 429, type: SafeErrorResponse, description: 'Limite de chamadas excedido.' })
@ApiResponse({ status: 503, type: SafeErrorResponse, description: 'Validação de sessão temporariamente indisponível.' })
@ApiResponse({ status: 500, type: SafeErrorResponse, description: 'Falha interna sem divulgação de detalhes.' })
class MeController {
  @Get()
  @ApiOkResponse({ type: ProfileResponse })
  me(@Req() request: AuthenticatedRequest) { return { id: request.user.id, plan: 'FREE' }; }
  @Get('entitlements')
  @ApiOkResponse({ type: EntitlementsResponse })
  entitlements() { return freeEntitlements(); }
}

export async function createApp(dependencies: AppDependencies) {
  @Module({
    imports: [ThrottlerModule.forRoot([{ ttl: 60_000, limit: dependencies.rateLimit ?? 60 }])],
    controllers: [HealthController, MeController],
    providers: [
      { provide: DEPENDENCIES, useValue: dependencies },
      { provide: APP_GUARD, useClass: ThrottlerGuard },
      { provide: APP_GUARD, useFactory: () => new AuthGuard(dependencies) },
      { provide: APP_GUARD, useClass: UserThrottlerGuard },
    ],
  })
  class AppModule {}
  const app = await NestFactory.create(AppModule, { logger: false, bodyParser: true });
  app.getHttpAdapter().getInstance().disable('x-powered-by');
  app.use(helmet());
  app.use((request: Request, response: Response, next: NextFunction) => {
    response.setHeader('x-request-id', randomUUID());
    response.setHeader('cache-control', 'no-store');
    const started = performance.now();
    response.on('finish', () => dependencies.log?.({
      requestId: response.getHeader('x-request-id'),
      route: request.route?.path ?? 'unmatched',
      method: request.method,
      status: response.statusCode,
      durationMs: Math.round(performance.now() - started),
    }));
    next();
  });
  app.enableCors({ origin: (origin: string | undefined, callback: (error: Error | null, allow?: boolean) => void) => callback(null, !origin || dependencies.origins.includes(origin)), credentials: false });
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
  app.useGlobalFilters(new SafeExceptionFilter());
  return app;
}

export function createOpenApi(app: INestApplication) {
  return SwaggerModule.createDocument(app, new DocumentBuilder()
    .setTitle('Estuda Aí API').setVersion('0.1.0').addBearerAuth().build());
}
