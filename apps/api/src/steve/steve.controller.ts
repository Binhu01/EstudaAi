import { Body, Controller, HttpCode, Inject, Post, Req, Res, ServiceUnavailableException } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiResponse, ApiTags } from '@nestjs/swagger';
import { Response } from 'express';
import { AuthenticatedRequest } from '../auth/auth.guard';
import { AppDependencies, DEPENDENCIES } from '../contracts';
import { SteveInputDto, SteveReplyDto } from './steve.dto';
@ApiTags('Steve') @ApiBearerAuth()
@Controller('v1/steve')
export class SteveController {
  constructor(@Inject(DEPENDENCIES) private readonly dependencies:AppDependencies) {}
  @Post('messages') @HttpCode(200)
  @ApiOkResponse({type:SteveReplyDto})
  @ApiResponse({status:400,description:'Assunto, mensagem ou histórico inválidos.'})
  @ApiResponse({status:401,description:'Entre na sua conta.'})
  @ApiResponse({status:413,description:'Mensagem muito grande.'})
  @ApiResponse({status:429,description:'Aguarde ou volte após a renovação da cota diária (resetAt).'})
  @ApiResponse({status:503,description:'Steve temporariamente indisponível.'})
  async reply(@Body() input:SteveInputDto,@Req() request:AuthenticatedRequest,@Res({passthrough:true}) response:Response) {
    if (!this.dependencies.steve) throw new ServiceUnavailableException();
    const abort=new AbortController();
    const onAborted=()=>abort.abort();
    const onClose=()=>{if (!response.writableEnded) abort.abort();};
    request.once('aborted',onAborted); response.once('close',onClose);
    if (request.aborted) abort.abort();
    try { return await this.dependencies.steve.reply(request.user.id,input,abort.signal,String(response.getHeader('x-request-id'))); }
    finally {request.removeListener('aborted',onAborted);response.removeListener('close',onClose);}
  }
}
