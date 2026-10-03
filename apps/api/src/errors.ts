import { ArgumentsHost, Catch, ExceptionFilter, HttpException } from '@nestjs/common';
import { Response } from 'express';
export class HistoryConflict extends HttpException { constructor(){super('Resposta incompatível com o registro existente.',409);} }
export class HistoryContentChanged extends HttpException { constructor(){super('O conteúdo foi atualizado. Abra a versão atual.',409);} }
export class DailyQuotaExceeded extends HttpException {
  constructor(readonly resetAt:string) { super('Limite diário atingido.',429); }
}

const errors: Record<number, readonly [string, string]> = {
  400: ['INVALID_INPUT', 'Verifique os dados enviados.'],
  401: ['UNAUTHENTICATED', 'Entre na sua conta para continuar.'],
  403: ['FORBIDDEN', 'Esta ação não está disponível.'],
  404: ['NOT_FOUND', 'Recurso não encontrado.'],
  413: ['PAYLOAD_TOO_LARGE', 'A mensagem é muito grande. Reduza o conteúdo e tente novamente.'],
  429: ['RATE_LIMITED', 'Aguarde um momento e tente novamente.'],
  503: ['UNAVAILABLE', 'Serviço temporariamente indisponível.'],
};
@Catch()
export class SafeExceptionFilter implements ExceptionFilter {
  catch(error: unknown, host: ArgumentsHost) {
    const response = host.switchToHttp().getResponse<Response>();
    if(error instanceof HistoryConflict||error instanceof HistoryContentChanged){
      response.status(409).json({code:error instanceof HistoryConflict?'CONFLICT':'CONTENT_CHANGED',message:error.message,requestId:response.getHeader('x-request-id')});return;
    }
    const parserError = error as {type?:unknown;status?:unknown} | null;
    const status = error instanceof HttpException ? error.getStatus()
      : parserError?.type === 'entity.too.large' && parserError.status === 413 ? 413
      : parserError?.type === 'entity.parse.failed' && parserError.status === 400 ? 400 : 500;
    const [code, message] = errors[status] ?? ['INTERNAL_ERROR', 'Não foi possível concluir esta ação.'];
    if (error instanceof DailyQuotaExceeded) {
      response.setHeader('retry-after',Math.max(1,Math.ceil((Date.parse(error.resetAt)-Date.now())/1000)));
      response.status(429).json({code,message:'O limite diário do Steve foi atingido. Volte após a renovação da cota.',resetAt:error.resetAt,requestId:response.getHeader('x-request-id')});
      return;
    }
    response.status(status).json({ code, message, requestId: response.getHeader('x-request-id') });
  }
}
