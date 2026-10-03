import {ApiProperty,ApiPropertyOptional} from '@nestjs/swagger';
import {Type} from 'class-transformer';
import {IsIn,IsInt,IsOptional,IsString,Max,MaxLength,Min,Matches} from 'class-validator';
export class EmptyStudyDto {}
export class DailyTargetDto{@ApiProperty({enum:[5,10,20]}) @IsIn([5,10,20]) dailyTarget!:5|10|20;}
export class StudyAnswerDto{
 @ApiProperty() @IsString() @Matches(/^[a-z0-9-]+$/) @MaxLength(100) topicId!:string;
 @ApiProperty({minimum:1}) @IsInt() @Min(1) contentVersion!:number;
 @ApiProperty() @IsString() @Matches(/^[a-z0-9-]+$/) @MaxLength(100) questionId!:string;
 @ApiProperty({minimum:0,maximum:3}) @IsInt() @Min(0) @Max(3) optionIndex!:number;
 @ApiProperty({enum:['quiz','review']}) @IsIn(['quiz','review']) source!:'quiz'|'review';
}
export class ErrorsQueryDto{
 @ApiPropertyOptional({enum:['pending','reviewed'],default:'pending'}) @IsIn(['pending','reviewed']) status:'pending'|'reviewed'='pending';
 @ApiPropertyOptional() @IsOptional() @IsString() @Matches(/^[a-z0-9-]+$/) @MaxLength(100) subjectId?:string;
 @ApiPropertyOptional({minimum:1,maximum:50,default:20}) @Type(()=>Number) @IsInt() @Min(1) @Max(50) limit=20;
 @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(4096) cursor?:string;
}
export class StudyGoalDto{
 @ApiProperty({format:'uuid'}) id!:string;
 @ApiProperty({enum:['freeStudy','bb2026']}) scope!:string;
 @ApiProperty({example:'America/Sao_Paulo'}) timezone!:string;
 @ApiProperty({enum:[5,10,20]}) dailyTarget!:number;
}
export class ConfirmedAnswerDto extends StudyAnswerDto{
 @ApiProperty({format:'uuid'}) answerId!:string;
 @ApiProperty({format:'uuid'}) goalId!:string;
 @ApiProperty() correct!:boolean;
 @ApiProperty({format:'date-time'}) receivedAt!:string;
}
export class DailyActivityDto{
 @ApiProperty({format:'date'}) date!:string;
 @ApiProperty({minimum:0}) differentQuestions!:number;
 @ApiProperty({minimum:0}) attempts!:number;
 @ApiProperty({minimum:0}) correct!:number;
}
export class SubjectStatsDto{
 @ApiProperty() id!:string; @ApiProperty() title!:string;
 @ApiProperty({minimum:0}) attempts!:number; @ApiProperty({minimum:0}) correct!:number;
}
export class ResumeStudyDto{@ApiProperty() topicId!:string; @ApiProperty({minimum:1}) contentVersion!:number;}
export class StudyDashboardDto{
 @ApiProperty({type:StudyGoalDto}) goal!:StudyGoalDto;
 @ApiProperty({type:DailyActivityDto}) today!:DailyActivityDto;
 @ApiProperty({minimum:0}) pendingErrors!:number;
 @ApiProperty({type:[DailyActivityDto],minItems:7,maxItems:7}) activity!:DailyActivityDto[];
 @ApiProperty({type:[SubjectStatsDto]}) subjects!:SubjectStatsDto[];
 @ApiProperty({type:ResumeStudyDto,nullable:true}) resume!:ResumeStudyDto|null;
}
export class StudyErrorItemDto{
 @ApiProperty() topicId!:string; @ApiProperty({minimum:1}) contentVersion!:number; @ApiProperty() questionId!:string;
 @ApiProperty({minimum:1}) wrongCount!:number;
 @ApiProperty({format:'date-time'}) firstWrongAt!:string; @ApiProperty({format:'date-time'}) lastWrongAt!:string; @ApiProperty({format:'date-time'}) lastAnswerAt!:string;
 @ApiProperty({minimum:0,maximum:3}) lastOptionIndex!:number;
 @ApiProperty({enum:['pending','reviewed']}) status!:string; @ApiProperty({enum:['current','outdated']}) contentStatus!:string;
}
export class StudyErrorPageDto{@ApiProperty({type:[StudyErrorItemDto]}) items!:StudyErrorItemDto[]; @ApiProperty({type:String,nullable:true}) nextCursor!:string|null;}
