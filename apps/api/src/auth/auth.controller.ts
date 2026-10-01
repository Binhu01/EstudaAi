import { Body, Controller, HttpCode, Inject, Post, ServiceUnavailableException } from '@nestjs/common';
import { ApiOkResponse, ApiResponse, ApiTags } from '@nestjs/swagger';
import { AppDependencies, DEPENDENCIES } from '../contracts';
import { PublicRoute } from './public-route';
import { RateGroup } from './rate.guards';
import { EmailDto, LoginDto, RegisterDto, RefreshDto, AuthSessionDto, ResetAcceptedDto } from './auth.dto';
@ApiTags('auth')
@PublicRoute()
@Controller('v1/auth')
@ApiResponse({status:400,description:'Dados inválidos.'})
@ApiResponse({status:401,description:'Não foi possível autenticar com esses dados.'})
@ApiResponse({status:429,description:'Aguarde antes de tentar novamente.'})
@ApiResponse({status:503,description:'Autenticação temporariamente indisponível.'})
export class AuthController {
  constructor(@Inject(DEPENDENCIES) private readonly dependencies: AppDependencies) {}
  private gateway() { if (!this.dependencies.auth) throw new ServiceUnavailableException(); return this.dependencies.auth; }
  @Post('register') @HttpCode(200) @RateGroup('auth') @ApiOkResponse({type:AuthSessionDto})
  register(@Body() body: RegisterDto) { return this.gateway().register(body.email,body.password); }
  @Post('login') @HttpCode(200) @RateGroup('auth') @ApiOkResponse({type:AuthSessionDto})
  login(@Body() body: LoginDto) { return this.gateway().login(body.email,body.password); }
  @Post('refresh') @HttpCode(200) @RateGroup('refresh') @ApiOkResponse({type:AuthSessionDto})
  refresh(@Body() body: RefreshDto) { return this.gateway().refresh(body.refreshToken); }
  @Post('password-reset') @HttpCode(200) @RateGroup('auth') @ApiOkResponse({type:ResetAcceptedDto})
  async reset(@Body() body: EmailDto) { await this.gateway().resetPassword(body.email); return {accepted:true}; }
}
