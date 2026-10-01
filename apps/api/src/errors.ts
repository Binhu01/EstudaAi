import { ArgumentsHost, Catch, ExceptionFilter, HttpException } from '@nestjs/common';
import { Response } from 'express';

const errors: Record<number, readonly [string, string]> = {
  400: ['INVALID_INPUT', 'Verifique os dados enviados.'],
  401: ['UNAUTHENTICATED', 'Entre na sua conta para continuar.'],
  403: ['FORBIDDEN', 'Esta ação não está disponível.'],
  404: ['NOT_FOUND', 'Recurso não encontrado.'],
  429: ['RATE_LIMITED', 'Aguarde um momento e tente novamente.'],
  503: ['UNAVAILABLE', 'Serviço temporariamente indisponível.'],
};
@Catch()
export class SafeExceptionFilter implements ExceptionFilter {
  catch(error: unknown, host: ArgumentsHost) {
    const response = host.switchToHttp().getResponse<Response>();
    const status = error instanceof HttpException ? error.getStatus() : 500;
    const [code, message] = errors[status] ?? ['INTERNAL_ERROR', 'Não foi possível concluir esta ação.'];
    response.status(status).json({ code, message, requestId: response.getHeader('x-request-id') });
  }
}
