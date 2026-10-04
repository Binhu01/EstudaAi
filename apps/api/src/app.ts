import 'reflect-metadata';
import { Controller, ExecutionContext, Get, Inject, Injectable, INestApplication, Module, Req, ServiceUnavailableException, ValidationPipe } from '@nestjs/common';
import { APP_GUARD, NestFactory } from '@nestjs/core';
import { SkipThrottle, ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { SwaggerModule, DocumentBuilder, ApiBearerAuth, ApiOkResponse, ApiProperty, ApiUnauthorizedResponse, ApiResponse } from '@nestjs/swagger';
import helmet from 'helmet';
import { randomUUID } from 'node:crypto';
import { Request, Response, NextFunction, json } from 'express';
import { SteveController } from './steve/steve.controller';
import { StudyController } from './study/study.controller';
import { AppDependencies, DEPENDENCIES } from './contracts';
import { AuthController } from './auth/auth.controller';
import { IpThrottlerGuard, UserThrottlerGuard } from './auth/rate.guards';
import { AuthGuard, AuthenticatedRequest } from './auth/auth.guard';
import { SafeExceptionFilter } from './errors';
import { freeEntitlements } from './entitlements/entitlements';
import { PublicRoute } from './auth/public-route';


class ProfileResponse {
  @ApiProperty({ format: 'uuid' }) id!: string;
  @ApiProperty({ enum: ['FREE'] }) plan!: string;
}
class CapabilitiesResponse {
  @ApiProperty({example:true}) steve!: boolean;
  @ApiProperty({ example: false }) advancedAi!: boolean;
  @ApiProperty({ example: false }) generatedQuestions!: boolean;
  @ApiProperty({ example: false }) advancedAnalytics!: boolean;
}
class LimitsResponse { @ApiProperty({example:10,minimum:1}) steveDailyMessages!: number; }
class EntitlementsResponse {
  @ApiProperty({ enum: ['FREE'] }) plan!: string;
  @ApiProperty({ type: CapabilitiesResponse }) capabilities!: CapabilitiesResponse;
  @ApiProperty({type:LimitsResponse}) limits!: LimitsResponse;
}
class SafeErrorResponse {
  @ApiProperty({ enum: ['INVALID_INPUT', 'UNAUTHENTICATED', 'FORBIDDEN', 'NOT_FOUND', 'CONFLICT', 'CONTENT_CHANGED', 'PAYLOAD_TOO_LARGE', 'RATE_LIMITED', 'UNAVAILABLE', 'INTERNAL_ERROR'] }) code!: string;
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
  constructor(@Inject(DEPENDENCIES) private readonly dependencies:AppDependencies) {}
  @Get()
  @ApiOkResponse({ type: ProfileResponse })
  me(@Req() request: AuthenticatedRequest) { return { id: request.user.id, plan: 'FREE' }; }
  @Get('entitlements')
  @ApiOkResponse({ type: EntitlementsResponse })
  entitlements() { return freeEntitlements(this.dependencies.steveDailyLimit); }
}

export async function createApp(dependencies: AppDependencies) {
  @Module({
    imports: [ThrottlerModule.forRoot([{ ttl: 60_000, limit: dependencies.rateLimit ?? 60 }])],
    controllers: [HealthController, MeController, AuthController, SteveController, StudyController],
    providers: [
      { provide: DEPENDENCIES, useValue: dependencies },
      { provide: APP_GUARD, useClass: IpThrottlerGuard },
      { provide: APP_GUARD, useFactory: () => new AuthGuard(dependencies) },
      { provide: APP_GUARD, useClass: UserThrottlerGuard },
    ],
  })
  class AppModule {}
  const app = await NestFactory.create(AppModule, { logger: false, bodyParser: false });
  app.getHttpAdapter().getInstance().disable('x-powered-by');
  app.getHttpAdapter().getInstance().set('trust proxy', dependencies.trustedProxyCidrs?.length ? [...dependencies.trustedProxyCidrs] : false);
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
  app.use(json({limit:'64kb'}));
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
  app.useGlobalFilters(new SafeExceptionFilter());
  return app;
}

export function createOpenApi(app: INestApplication, topicIds: readonly string[]) {
  const document = SwaggerModule.createDocument(app, new DocumentBuilder()
    .setTitle('Estuda Aí API').setVersion('0.1.0').addBearerAuth().build());
  for (const name of ['SteveInputDto', 'SteveReplyDto', 'StudyAnswerDto', 'ConfirmedAnswerDto', 'StudyErrorItemDto', 'ResumeStudyDto']) {
    const schema = document.components?.schemas?.[name];
    if (schema && 'properties' in schema && schema.properties?.topicId) {
      schema.properties.topicId = {type:'string', enum:[...topicIds]};
    }
  }
  return document;
}
