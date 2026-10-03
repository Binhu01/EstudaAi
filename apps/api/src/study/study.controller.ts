import {Body,Controller,Get,HttpCode,HttpException,Inject,Param,ParseUUIDPipe,Patch,Post,Put,Query,Req,ServiceUnavailableException,BadRequestException} from '@nestjs/common';
import {ApiBearerAuth,ApiOkResponse,ApiResponse,ApiTags,ApiParam} from '@nestjs/swagger';
import {AuthenticatedRequest} from '../auth/auth.guard';
import {AppDependencies,DEPENDENCIES} from '../contracts';
import {StudyScope} from './study.models';
import {StudyHistoryService} from './study.service';
import {EmptyStudyDto,DailyTargetDto,StudyAnswerDto,ErrorsQueryDto,StudyGoalDto,ConfirmedAnswerDto,StudyDashboardDto,StudyErrorPageDto} from './study.dto';
@ApiTags('study') @ApiBearerAuth()
@ApiResponse({status:400,description:'Entrada inválida.'}) @ApiResponse({status:401,description:'Entre na sua conta.'}) @ApiResponse({status:404,description:'Meta não encontrada.'}) @ApiResponse({status:409,description:'CONFLICT ou CONTENT_CHANGED.'}) @ApiResponse({status:429,description:'Aguarde antes de tentar novamente.'}) @ApiResponse({status:503,description:'Histórico temporariamente indisponível.'})
@Controller('v1')
export class StudyController{
 constructor(@Inject(DEPENDENCIES) private readonly deps:AppDependencies){}
 private async use<T>(work:(service:StudyHistoryService)=>Promise<T>){
  if(!this.deps.study)throw new ServiceUnavailableException();
  try{return await work(this.deps.study);}catch(error){if(error instanceof HttpException)throw error;throw new ServiceUnavailableException();}
 }
 @Post('study-contexts/:scope/ensure') @HttpCode(200) @ApiParam({name:'scope',enum:['freeStudy','bb2026']}) @ApiOkResponse({type:StudyGoalDto})
 ensure(@Param('scope') scope:StudyScope,@Body() _body:EmptyStudyDto,@Req() req:AuthenticatedRequest){
  if(scope!=='freeStudy'&&scope!=='bb2026')throw new BadRequestException();return this.use(s=>s.ensureContext(req.user.id,scope));
 }
 @Patch('goals/:goalId/daily-target') @ApiOkResponse({type:StudyGoalDto})
 target(@Param('goalId',new ParseUUIDPipe()) goalId:string,@Body() body:DailyTargetDto,@Req() req:AuthenticatedRequest){return this.use(s=>s.setDailyTarget(req.user.id,goalId,body.dailyTarget));}
 @Put('goals/:goalId/answers/:answerId') @ApiOkResponse({type:ConfirmedAnswerDto})
 answer(@Param('goalId',new ParseUUIDPipe()) goalId:string,@Param('answerId',new ParseUUIDPipe()) answerId:string,@Body() body:StudyAnswerDto,@Req() req:AuthenticatedRequest){return this.use(s=>s.confirmAnswer(req.user.id,goalId,answerId,body));}
 @Get('goals/:goalId/dashboard') @ApiOkResponse({type:StudyDashboardDto})
 dashboard(@Param('goalId',new ParseUUIDPipe()) goalId:string,@Req() req:AuthenticatedRequest){return this.use(s=>s.readDashboard(req.user.id,goalId));}
 @Get('goals/:goalId/errors') @ApiOkResponse({type:StudyErrorPageDto})
 errors(@Param('goalId',new ParseUUIDPipe()) goalId:string,@Query() query:ErrorsQueryDto,@Req() req:AuthenticatedRequest){return this.use(s=>s.listErrors(req.user.id,goalId,query));}
}
